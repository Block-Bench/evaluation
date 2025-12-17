"""
Base client interface for LLM Judge.
"""

from abc import ABC, abstractmethod
import asyncio
from typing import Optional

from .schemas import JudgeInput, JudgeOutput
from .config import JudgeModelConfig


class BaseJudgeClient(ABC):
    """Abstract base class for judge model clients"""

    def __init__(self, config: JudgeModelConfig):
        self.config = config
        self._setup_client()

    @abstractmethod
    def _setup_client(self):
        """Initialize the model client"""
        pass

    @abstractmethod
    async def evaluate(self, input: JudgeInput) -> JudgeOutput:
        """Evaluate a single sample"""
        pass

    async def evaluate_with_retry(
        self,
        input: JudgeInput,
        max_retries: Optional[int] = None,
        retry_delay: Optional[float] = None
    ) -> JudgeOutput:
        """Evaluate with retry logic"""
        max_retries = max_retries or self.config.max_retries
        retry_delay = retry_delay or self.config.retry_delay

        last_error = None
        for attempt in range(max_retries):
            try:
                return await self.evaluate(input)
            except Exception as e:
                last_error = e
                if attempt < max_retries - 1:
                    wait_time = retry_delay * (2 ** attempt)
                    print(f"  Retry {attempt + 1}/{max_retries} after {wait_time}s: {e}")
                    await asyncio.sleep(wait_time)

        raise last_error

    async def evaluate_batch(
        self,
        inputs: list[JudgeInput],
        max_concurrency: int = 5
    ) -> list[JudgeOutput]:
        """Evaluate multiple samples with concurrency control"""
        semaphore = asyncio.Semaphore(max_concurrency)

        async def bounded_evaluate(input: JudgeInput) -> JudgeOutput:
            async with semaphore:
                return await self.evaluate_with_retry(input)

        return await asyncio.gather(*[bounded_evaluate(i) for i in inputs])
