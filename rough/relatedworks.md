%% BlockBench Related Works Section - Main Paper Body
%% Approximately 800 words / ~1.5 pages in ACL format
%% Revised to avoid emdashes and colons

\section{Related Work}

\subsection{Traditional Smart Contract Analysis}

Static and dynamic analysis tools remain foundational for vulnerability detection. Slither \cite{feist2019slither} performs dataflow analysis, Mythril \cite{mueller2017mythril} uses symbolic execution, and Securify \cite{tsankov2018securify} employs abstract interpretation. Empirical evaluation reveals significant limitations. On 69 annotated contracts, tools detect only 27--42\% of vulnerabilities, while flagging 97\% of 47,587 real-world Ethereum contracts as vulnerable, indicating high false positive rates that render output practically unusable \cite{durieux2020empirical}.

Recent systematic comparison confirms that LLM-based tools are ``not ready to replace'' traditional analyzers \cite{ince2025gendetect}. However, the tools exhibit complementary strengths. Traditional analyzers outperform on well-documented vulnerabilities such as reentrancy and unchecked calls, while LLMs show advantages on transaction order dependency and complex logic errors. This suggests hybrid approaches may prove most effective.

\subsection{LLM-Based Vulnerability Detection}

\paragraph{Prompt-Based Approaches.}
Early work explores direct prompting of general-purpose LLMs. David et al. \cite{david2023manual} evaluate GPT-4 and Claude on smart contract auditing, achieving approximately 40\% detection rates with high false positive rates. Chen et al. \cite{chen2023chatgpt} systematically evaluate ChatGPT, finding only 22\% precision on real-world contracts. Their analysis reveals ``shallow pattern matching'' where models flag contracts as vulnerable based on security-suggestive variable names rather than program logic, with detection degrading substantially when identifiers are neutralized.

\paragraph{Hybrid LLM-Static Analysis.}
GPTScan \cite{sun2023gptscan} pioneered combining GPT with static analysis for logic vulnerability detection, decomposing vulnerability types into scenarios and properties for semantic matching. PropertyGPT \cite{liu2024propertygpt} extends this paradigm through retrieval-augmented generation with formal verification. iAudit \cite{ma2024combining} implements incremental function-by-function analysis with contextual memory. While achieving improved benchmark performance, these approaches inherit limitations from both components.

\paragraph{Multi-Agent Frameworks.}
Several frameworks employ multiple LLM agents in collaborative configurations. GPTLens \cite{hu2023gptlens} separates detection into generation (auditor) and discrimination (critic) stages. Critically, the authors document output drift, observing that `GPT-4 could easily identify the vulnerability on September 16 but had difficulty detecting it on September 28'' even with temperature set to zero. This instability required few-shot examples to`stabilize'' the critic, suggesting memorization-based rather than reasoning-based operation.

LLM-SmartAudit \cite{wei2024llmsmartaudit} implements multi-agent collaboration with specialized auditor roles. LLMBugScanner \cite{fang2024llmbugscanner} uses ensemble voting across GPT-4, Claude, and Gemini, finding 10.3\% hallucination rates and observing that models share blind spots, limiting ensemble diversity benefits. SmartLLMSentry \cite{xu2024smartllmsentry} takes a distinctive approach by using LLMs to generate detection rules applied deterministically, with GPT-3 outperforming GPT-4 for rule generation.

\paragraph{Fine-Tuning Approaches.}
Supervised fine-tuning shows consistent but bounded improvements. Smart-LLaMA \cite{li2024smartllama} applies Direct Preference Optimization to enhance both detection and explanation. QLoRA fine-tuning of Llama-2-7B achieves 59.9\% accuracy \cite{boi2024role}, documenting a ceiling that appears consistent across approaches. Notably, architectural choices matter. A 3B parameter model with classification head achieves 77.5\% accuracy matching 175B GPT-3.5, with vulnerability patterns localized in upper transformer layers \cite{sikder2025efficient}. This suggests the bottleneck is evaluation methodology rather than raw capability.

\subsection{The Accuracy-Understanding Gap}

A critical finding emerges across studies. High accuracy coexists with low genuine understanding. LLM4Vuln \cite{sun2024llm4vuln} explicitly decouples detection from reasoning, finding models identify vulnerability presence without explaining root causes. The framework reveals that difficult samples expose reasoning failures invisible in standard evaluation.

Chen et al. \cite{chen2023chatgpt} report models correctly classifying contracts as vulnerable while identifying wrong vulnerability types. These ``lucky guesses'' inflate accuracy metrics. This pattern appears consistently, with models achieving 88\% binary classification accuracy yet only 18\% target detection rate when required to identify specific vulnerability types and locations.

\subsection{Evidence for Pattern Memorization}

Beyond smart contracts, broader LLM evaluation reveals systematic memorization concerns. Wu et al. \cite{wu2024reasoning} demonstrate that models fail on counterfactual variations despite solving canonical problem forms. Sánchez Salido et al. \cite{sanchez2025none} show performance drops exceeding 57\% on semantically-equivalent paraphrased questions.

In security contexts, this manifests as surface pattern dependence. The output drift documented in GPTLens provides direct evidence, with different results on identical inputs across time periods even with deterministic settings. This shows that detection relies on unstable learned associations rather than robust semantic understanding. The need for two-stage auditor-critic architectures itself suggests models lack unified security reasoning. If genuine understanding existed, generation would not be ``fundamentally harder than discrimination'' \cite{hu2023gptlens}.

\subsection{Benchmarks and Evaluation Gaps}

SmartBugs Curated \cite{ferreira2020smartbugs} provides 143 annotated contracts as a standard dataset. VulBench \cite{gao2023vulbench} offers comprehensive evaluation combining CTF challenges with real-world samples. The Awesome-LLM4Cybersecurity survey \cite{tmylla2024awesome} catalogs over 90 vulnerability detection papers, noting a critical gap. None of these works ``specifically evaluate whether models understand vulnerabilities versus memorizing patterns.''

Existing benchmarks share key limitations. First, temporal contamination arises from samples appearing in training corpora. Second, evaluation focuses on detection accuracy without reasoning quality assessment. Third, no adversarial testing distinguishes memorization from understanding. Our work addresses these gaps through post-cutoff Gold Standard samples, composite metrics capturing reasoning quality, and systematic adversarial transformations that preserve vulnerability semantics while removing surface cues.

%% ============================================
%% REFERENCES TO ADD TO YOUR .bib FILE
%% ============================================

% @inproceedings{sun2024llm4vuln,
% title={{LLM4Vuln}: A Unified Evaluation Framework for Decoupling and Enhancing {LLMs'} Vulnerability Reasoning},
% author={Sun, Yuqiang and Wu, Daoyuan and Xue, Yue and Liu, Han and Ma, Wei and Zhang, Lyuye and Shi, Miaolei and Liu, Yang},
% booktitle={arXiv preprint arXiv:2401.16185},
% year={2024}
% }

% @inproceedings{sun2023gptscan,
% title={When {GPT} Meets Program Analysis: Towards Intelligent Detection of Smart Contract Logic Vulnerabilities in {GPTScan}},
% author={Sun, Yuqiang and Wu, Daoyuan and Xue, Yue and Liu, Han and Wang, Haijun and Xu, Zhengzi and Xie, Xiaofei and Liu, Yang},
% booktitle={ICSE},
% year={2024}
% }

% @article{hu2023gptlens,
% title={Large Language Model-Powered Smart Contract Vulnerability Detection: New Perspectives},
% author={Hu, Sihao and Huang, Tiansheng and Liu, Feiyang and Ge, Sunjun and Liu, Ling},
% journal={arXiv preprint arXiv:2310.01152},
% year={2023}
% }

% @article{chen2023chatgpt,
% title={When {ChatGPT} Meets Smart Contract Vulnerability Detection: How Far Are We?},
% author={Chen, Chong and Nie, Jianzhong and Peng, Xingyu and Yang, Jian and Wang, Dan and Zhuo, Jiayuan and Liu, Zhenqi and Yang, Zhun},
% journal={arXiv preprint arXiv:2309.05520},
% year={2023}
% }

% @inproceedings{ince2025gendetect,
% title={{GenDetect}: Generative Large Language Model Usage in Smart Contract Vulnerability Detection},
% author={Ince, Peter and Yu, Jiangshan and Liu, Joseph K. and Du, Xiaoning and Luo, Xiapu},
% booktitle={ProvSec 2025},
% year={2025},
% publisher={Springer}
% }

% @article{david2023manual,
% title={Do You Still Need a Manual Smart Contract Audit?},
% author={David, Isaac and others},
% journal={arXiv preprint arXiv:2306.12338},
% year={2023}
% }

% @article{wei2024llmsmartaudit,
% title={{LLM-SmartAudit}: Advanced Smart Contract Vulnerability Detection},
% author={Wei, Zhiyuan and Sun, Jing and Zhang, Zijiang and Zhang, Xianhao},
% journal={arXiv preprint arXiv:2403.04075},
% year={2024}
% }

% @article{fang2024llmbugscanner,
% title={{LLMBugScanner}: A Practical Tool for {LLM}-based Bug Scanning},
% author={Fang, Enyue and Liu, Boyu and Wang, Weisong and others},
% journal={arXiv preprint arXiv:2401.15468},
% year={2024}
% }

% @article{xu2024smartllmsentry,
% title={{SmartLLMSentry}: A Tool for Smart Contract Vulnerability Detection},
% author={Xu, Jie and others},
% year={2024}
% }

% @article{li2024smartllama,
% title={{Smart-LLaMA}: Two-Stage Post-Training of Large Language Models for Smart Contract Vulnerability Detection and Explanation},
% author={Li, Lei and Zhang, Haowei and others},
% journal={arXiv preprint arXiv:2411.06221},
% year={2024}
% }

% @article{boi2024role,
% title={Smart Contract Vulnerability Detection: Role of {LLM}},
% author={Boi, Biagio and Esposito, Christian and Lee, Sokjoon},
% journal={ACM SIGAPP Applied Computing Review},
% volume={24},
% number={2},
% year={2024}
% }

% @inproceedings{sikder2025efficient,
% title={Efficient Adaptation of Large Language Models for Smart Contract Vulnerability Detection},
% author={Sikder, Fadul and Lei, Yu and Ji, Yuede},
% booktitle={PROMISE '25},
% year={2025}
% }

% @article{ma2024combining,
% title={{iAudit}: Combining LLMs and Static Analysis for Incremental Smart Contract Auditing},
% author={Ma, Weimin and others},
% year={2024}
% }

% @article{liu2024propertygpt,
% title={{PropertyGPT}: {LLM}-driven Formal Verification of Smart Contracts through Retrieval-Augmented Property Generation},
% author={Liu, Ye and Xue, Yue and Wu, Daoyuan and Sun, Yuqiang and Li, Yi and Shi, Miaolei and Liu, Yang},
% journal={arXiv preprint arXiv:2405.02580},
% year={2024}
% }

% @article{gao2023vulbench,
% title={How Far Have We Gone in Vulnerability Detection Using Large Language Models},
% author={Gao, Zeyu and others},
% journal={arXiv preprint arXiv:2311.12420},
% year={2023}
% }

% @article{wu2024reasoning,
% title={Reasoning or Reciting? Exploring the Capabilities and Limitations of Language Models through Counterfactual Tasks},
% author={Wu, Zhaofeng and Qiu, Linlu and Ross, Alexis and Aky{\"u}rek, Ekin and Chen, Boyuan and Wang, Bailin and Kim, Najoung and Andreas, Jacob and Kim, Yoon},
% journal={arXiv preprint arXiv:2307.02477},
% year={2024}
% }

% @article{sanchez2025none,
% title={None of the Others: A General Technique to Distinguish Reasoning from Memorization in Multiple-Choice {LLM} Evaluation Benchmarks},
% author={S{\'a}nchez Salido, Eva and Gonzalo, Julio and Marco, Guillermo},
% journal={arXiv preprint arXiv:2502.12896},
% year={2025}
% }

% @misc{tmylla2024awesome,
% title={Awesome-{LLM4Cybersecurity}: When {LLMs} Meet Cybersecurity},
% author={tmylla},
% howpublished={\url{https://github.com/tmylla/Awesome-LLM4Cybersecurity}},
% year={2024}
% }
