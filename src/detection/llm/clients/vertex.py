"""
Vertex AI unified client for multiple model providers.

Supports:
- Claude (via AnthropicVertex)
- Gemini (via google-genai)
- DeepSeek (via MaaS rawPredict)
- Llama (via MaaS chat/completions)
"""

import os
import time
import requests
from typing import Optional, Literal

from .base import BaseLLMClient, LLMResponse


VertexProvider = Literal["vertex_anthropic", "vertex_google", "deepseek", "vertex_llama"]


# Pricing per 1M tokens
VERTEX_PRICING = {
    "claude-opus-4-5@20251101": {"input": 15.0, "output": 75.0},
    "claude-haiku-4-5@20251001": {"input": 0.80, "output": 4.0},
    "gemini-3-pro-preview": {"input": 1.25, "output": 5.0},
    "gemini-2.5-pro": {"input": 1.25, "output": 5.0},
    "deepseek-ai/deepseek-v3.2-maas": {"input": 0.14, "output": 0.28},
    "meta/llama-4-maverick-17b-128e-instruct-maas": {"input": 0.27, "output": 0.35},
}


class VertexAIClient(BaseLLMClient):
    """
    Unified client for Vertex AI models.

    Automatically routes to the correct API based on provider type.
    """

    def __init__(
        self,
        model_id: str,
        provider: VertexProvider,
        region: str = "global",
        project_id: Optional[str] = None,
        endpoint: Optional[str] = None,
    ):
        super().__init__(model_name=model_id)
        self.model_id = model_id
        self.provider = provider
        self.region = region
        self.endpoint = endpoint

        # Get project ID from env vars or gcloud credentials
        self.project_id = project_id or os.getenv("VERTEX_PROJECT_ID") or os.getenv("GOOGLE_CLOUD_PROJECT")
        if not self.project_id:
            # Try to get from gcloud default credentials
            try:
                from google.auth import default
                _, self.project_id = default()
            except Exception:
                pass

        # Initialize provider-specific clients lazily
        self._anthropic_client = None
        self._genai_client = None

    def _get_anthropic_client(self):
        """Get or create AnthropicVertex client."""
        if self._anthropic_client is None:
            from anthropic import AnthropicVertex
            self._anthropic_client = AnthropicVertex(region=self.region)
        return self._anthropic_client

    def _get_genai_client(self):
        """Get or create google-genai client."""
        if self._genai_client is None:
            from google import genai
            self._genai_client = genai.Client(
                vertexai=True,
                project=self.project_id,
                location=self.region
            )
        return self._genai_client

    async def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.0,
        max_tokens: int = 4096
    ) -> LLMResponse:
        """Generate response using the appropriate Vertex AI provider."""

        if self.provider == "vertex_anthropic":
            return await self._generate_anthropic(system_prompt, user_prompt, temperature, max_tokens)
        elif self.provider == "vertex_google":
            return await self._generate_google(system_prompt, user_prompt, temperature, max_tokens)
        elif self.provider == "deepseek":
            return await self._generate_maas_openai(system_prompt, user_prompt, temperature, max_tokens)
        elif self.provider == "vertex_llama":
            return await self._generate_llama(system_prompt, user_prompt, temperature, max_tokens)
        else:
            raise ValueError(f"Unknown provider: {self.provider}")

    async def _generate_anthropic(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float,
        max_tokens: int
    ) -> LLMResponse:
        """Generate using AnthropicVertex."""
        client = self._get_anthropic_client()

        start_time = time.time()
        response = client.messages.create(
            model=self.model_id,
            max_tokens=max_tokens,
            system=system_prompt,
            messages=[{"role": "user", "content": user_prompt}]
        )
        latency_ms = (time.time() - start_time) * 1000

        input_tokens = response.usage.input_tokens
        output_tokens = response.usage.output_tokens

        return LLMResponse(
            content=response.content[0].text,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            cost_usd=self.calculate_cost(input_tokens, output_tokens),
            model=self.model_id,
            finish_reason=response.stop_reason
        )

    async def _generate_google(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float,
        max_tokens: int
    ) -> LLMResponse:
        """Generate using google-genai SDK."""
        from google.genai import types

        client = self._get_genai_client()

        start_time = time.time()
        response = client.models.generate_content(
            model=self.model_id,
            contents=[user_prompt],
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=temperature,
                max_output_tokens=max_tokens
            )
        )
        latency_ms = (time.time() - start_time) * 1000

        # Check for truncation
        finish_reason = None
        if response.candidates:
            finish_reason = response.candidates[0].finish_reason.name

        # Extract token counts from usage metadata
        input_tokens = getattr(response.usage_metadata, 'prompt_token_count', 0) if hasattr(response, 'usage_metadata') else 0
        output_tokens = getattr(response.usage_metadata, 'candidates_token_count', 0) if hasattr(response, 'usage_metadata') else 0

        return LLMResponse(
            content=response.text,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            cost_usd=self.calculate_cost(input_tokens, output_tokens),
            model=self.model_id,
            finish_reason=finish_reason
        )

    async def _generate_maas_openai(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float,
        max_tokens: int
    ) -> LLMResponse:
        """Generate using MaaS OpenAI-compatible endpoint (for DeepSeek)."""
        from openai import OpenAI
        import google.auth
        import google.auth.transport.requests

        # Get credentials
        credentials, project = google.auth.default()
        credentials.refresh(google.auth.transport.requests.Request())

        # Use project from credentials if not set
        project_id = self.project_id or project

        # Construct Vertex AI OpenAI-compatible endpoint
        # Global region uses a different base URL format
        if self.region == "global":
            base_url = (
                f"https://aiplatform.googleapis.com/v1/"
                f"projects/{project_id}/locations/global/endpoints/openapi"
            )
        else:
            base_url = (
                f"https://{self.region}-aiplatform.googleapis.com/v1/"
                f"projects/{project_id}/locations/{self.region}/endpoints/openapi"
            )

        client = OpenAI(
            base_url=base_url,
            api_key=credentials.token,
        )

        start_time = time.time()
        response = client.chat.completions.create(
            model=self.model_id,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
        )
        latency_ms = (time.time() - start_time) * 1000

        content = response.choices[0].message.content or ""
        input_tokens = response.usage.prompt_tokens if response.usage else 0
        output_tokens = response.usage.completion_tokens if response.usage else 0
        finish_reason = response.choices[0].finish_reason or "unknown"

        return LLMResponse(
            content=content,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            cost_usd=self.calculate_cost(input_tokens, output_tokens),
            model=self.model_id,
            finish_reason=finish_reason
        )

    async def _generate_llama(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float,
        max_tokens: int
    ) -> LLMResponse:
        """Generate using Llama via Vertex AI MaaS chat/completions endpoint."""
        from google.auth import default
        from google.auth.transport.requests import Request

        credentials, project = default()
        credentials.refresh(Request())

        # Llama uses us-east5 with special endpoint
        location = self.region or "us-east5"
        endpoint_host = self.endpoint or f"{location}-aiplatform.googleapis.com"
        endpoint = f"https://{endpoint_host}/v1/projects/{self.project_id}/locations/{location}/endpoints/openapi/chat/completions"

        headers = {
            "Authorization": f"Bearer {credentials.token}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": self.model_id,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": temperature,
            "max_tokens": max_tokens
        }

        start_time = time.time()
        response = requests.post(endpoint, headers=headers, json=payload, timeout=300)
        latency_ms = (time.time() - start_time) * 1000

        if response.status_code != 200:
            raise Exception(f"API call failed: {response.status_code} - {response.text[:200]}")

        data = response.json()

        content = data["choices"][0]["message"]["content"]
        input_tokens = data.get("usage", {}).get("prompt_tokens", 0)
        output_tokens = data.get("usage", {}).get("completion_tokens", 0)
        finish_reason = data["choices"][0].get("finish_reason")

        return LLMResponse(
            content=content,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            cost_usd=self.calculate_cost(input_tokens, output_tokens),
            model=self.model_id,
            finish_reason=finish_reason
        )

    def calculate_cost(self, input_tokens: int, output_tokens: int) -> float:
        """Calculate cost in USD."""
        pricing = VERTEX_PRICING.get(self.model_id, {"input": 0, "output": 0})
        input_cost = (input_tokens / 1_000_000) * pricing["input"]
        output_cost = (output_tokens / 1_000_000) * pricing["output"]
        return input_cost + output_cost
