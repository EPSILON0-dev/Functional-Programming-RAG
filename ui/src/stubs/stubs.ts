export const databases_stub = [
    { label: "Haskell" },
    { label: "JavaScript" },
    { label: "Very long database name" },
    { label: "Paradigms" },
];

export const conversations_stub = [
    { label: "Function \"map\"" },
    { label: "Monads" },
    { label: "RAG System Implementation" },
    { label: "Lambda Calculus Basics" },
    { label: "Type Inference" },
    { label: "Recursion vs Iteration" },
    { label: "Currying and Partial Application" },
    { label: "Algebraic Data Types" },
    { label: "Pattern Matching" },
    { label: "Higher-Order Functions" },
    { label: "Lazy Evaluation" },
    { label: "Functors and Applicatives" },
    { label: "Tail Call Optimization" },
    { label: "List Comprehensions" },
    { label: "State Monad" },
    { label: "Fold and Unfold" },
    { label: "Point-Free Style" },
    { label: "Category Theory Intro" },
    { label: "Dependent Types" },
    { label: "Pure Functions and Side Effects" },
    { label: "Continuation Passing Style" },
    { label: "Memoization Techniques" },
    { label: "Zipper Data Structure" },
];

export const presets_stub = [
    { label: "Deep Research" },
    { label: "Shallow Research" },
    { label: "No Research" },
];

export const chat_stub = [
    {
        prompt: "What's the difference between npu and tpu",
        response: `
At a glance, both **NPUs** and **TPUs** are silicon built to chew through AI workloads faster than a general CPU or even a GPU. But they come from slightly different design philosophies and ecosystems.

Let’s untangle them.

---

# 🧠 NPU (Neural Processing Unit)

A **Neural Processing Unit** is a **general-purpose AI accelerator** typically embedded inside consumer hardware.

### What it’s like

Think of an NPU as a **built-in AI sidekick** living inside your device, quietly handling neural network tasks without waking up the big, power-hungry cores.

### Where you find it

* Phones (e.g. Qualcomm Snapdragon chips)
* Laptops (e.g. Intel Core Ultra, AMD Ryzen AI)
* Edge devices, IoT boards

### Key traits

* Optimized for **low power consumption**
* Handles **inference** (running models, not training them)
* Works locally (offline AI, privacy-friendly)
* Supports a variety of model types (vision, audio, NLP)

### Typical use cases

* Face unlock
* Camera AI enhancements
* On-device LLM inference (small models)
* Noise suppression, speech recognition

---

# ⚡ TPU (Tensor Processing Unit)

A **Tensor Processing Unit** is a **specialized AI accelerator designed by Google**, mainly for large-scale machine learning.

### What it’s like

A TPU is less of a sidekick and more of a **factory assembly line for tensors**. It’s built to process huge batches of matrix operations at absurd speed.

### Where you find it

* Google Cloud
* Data centers
* Some edge variants (like Coral, but still niche)

### Key traits

* Extremely optimized for **matrix math (tensor ops)**
* Designed for both **training and inference**
* Massive parallelism
* Works best with frameworks like TensorFlow/JAX

### Typical use cases

* Training large models (LLMs, vision models)
* Running AI at cloud scale
* High-throughput inference pipelines

---

# ⚔️ NPU vs TPU — the core differences

| Aspect      | NPU                                     | TPU                  |
| ----------- | --------------------------------------- | -------------------- |
| Target      | Consumer devices                        | Data centers / cloud |
| Power usage | Very low                                | High                 |
| Main job    | Inference                               | Training + inference |
| Flexibility | More general AI tasks                   | Highly specialized   |
| Ecosystem   | Vendor-specific (Intel, Qualcomm, etc.) | Google-centric       |
| Scale       | Small, local                            | Massive, distributed |

---

# 🧩 The intuition

* **NPU** = *“Run this AI model efficiently on my device without draining battery.”*
* **TPU** = *“Train or run this giant model across racks of hardware as fast as physics allows.”*

---

# 🧠 Bonus nuance (the part people often miss)

The term **NPU** is a bit… fuzzy. It’s more of a **marketing umbrella** than a strict architecture. Different vendors implement NPUs very differently.

Meanwhile, **TPU** is a **specific architecture family** designed by Google, with tightly controlled software + hardware integration.

---

If you want, I can go deeper into:

* how NPUs compare to GPUs (that’s where things get spicy)
* or how to actually *use* an NPU on Linux / your projects (given your RISC-V + low-level interests, there’s some fun territory there)
`
    },
    {
        prompt: "How do they differ architecturally?",
        response: `
Now we’re getting into the circuitry guts rather than the marketing labels. Architecturally, NPUs and TPUs diverge in how they *move data*, *schedule computation*, and *represent math*.

---

# 🧠 The core split: flexible engines vs rigid pipelines

* **NPU** → a **collection of programmable compute blocks** (more like a tiny GPU tailored for neural nets)
* **TPU** → a **fixed-function matrix machine** built around a *systolic array*

That single design choice ripples into everything else.

---

# 🧩 1. Compute architecture

## NPU: heterogeneous compute units

An NPU usually contains:

* Vector units
* Scalar units
* Specialized MAC (multiply-accumulate) blocks
* Sometimes small tensor cores

Think: **“many small workers with different tools”**

It executes:

* Convolutions
* Attention
* Activations
* Custom ops

👉 Often **instruction-driven** (there *is* a program, even if hidden behind a compiler)

---

## TPU: systolic array (the big idea)

At the heart of a TPU:

C = A \times B

But implemented as a **grid of multiply-accumulate cells** where data flows rhythmically.

Think:

* Data enters from edges
* Moves cell-to-cell like a wave
* Each cell does: \`acc += a * b\`

👉 No complex instruction scheduling per unit
👉 The **dataflow *is* the program**

This is called a **systolic array**.

---

# 🔄 2. Dataflow & memory model

## NPU: cache + memory hierarchy

* Uses:

  * SRAM caches
  * Shared memory
  * DMA transfers
* Data moves like in GPUs/CPUs:

  * Load → compute → store

👉 More flexible, but:

* More overhead
* More energy spent moving data

---

## TPU: dataflow-driven (weight-stationary / output-stationary)

TPUs minimize memory movement:

* Weights or activations stay **in place**
* Data streams through the array

👉 Key idea:

> Moving data costs more energy than computing it

So TPUs:

* **Reuse data aggressively**
* Avoid round-trips to memory

---

# ⚙️ 3. Control logic

## NPU

* Has:

  * Instruction decoders
  * Schedulers
  * Control flow

👉 Can handle:

* Branching
* Irregular workloads
* Mixed model types

---

## TPU

* Minimal control logic
* Execution is:

  * Pre-planned
  * Compiled into dataflow

👉 Almost no branching inside the core compute

---

# 🔢 4. Precision & numerics

## NPU

* Supports many formats:

  * FP32, FP16
  * INT8, INT4
  * Sometimes mixed precision

👉 Designed to be **adaptable**

---

## TPU

* Aggressively optimized formats:

  * bfloat16 (very common)
  * INT8 for inference

👉 Precision choices are:

* **hardware-driven**
* tightly coupled to performance

---

# 🧱 5. Scalability philosophy

## NPU

* Scale **horizontally across devices**
* Each unit is relatively independent

---

## TPU

* Designed to scale **as one machine**
* Interconnects (TPU pods) behave like:

  * one giant accelerator

---

# 🧠 Mental model (the useful one)

If you had to visualize them:

* **NPU** → a *toolbox workshop*
  You pick tools, run instructions, adapt to the job.

* **TPU** → a *conveyor-belt factory*
  Once configured, it produces matrix multiplications at absurd speed with almost no deviation.

---

# 🧨 Why this matters in practice

* NPUs struggle less with:

  * small models
  * weird architectures
  * dynamic graphs

* TPUs dominate when:

  * workload = mostly matrix multiplies
  * model is large and regular
  * throughput > flexibility

---

# ⚡ Subtle but important takeaway

The real architectural divide is:

> **Instruction-driven vs dataflow-driven computing**

* NPU: *“what instruction do I execute next?”*
* TPU: *“how do I stream data through this fixed pipeline?”*

---

If you want, I can go one layer deeper and sketch:

* how systolic arrays are physically wired (it’s surprisingly elegant)
* or compare this to GPU tensor cores vs AVX512 (which ties nicely into your SIMD curiosity)
`
    },
    {
        prompt: "Are there any open-ish npus where I can read some docs and maybe instruction sets?",
        response: `
Short answer: **yes, but barely**. The open NPU world is still a small, slightly chaotic village compared to the GPU metropolis.

The **one genuinely “read-the-RTL, see-the-ISA” level project right now** is:

---

# 🧠 1. Google Coral NPU (the big one)

This is *exactly* what you’re looking for:
an **open-ish NPU with actual architecture, toolchain, and (some) instruction-level visibility**.

### What you get

* **RISC-V–based core** (so not a black box ISA)
* Distinct units:

  * Matrix engine (tensor ops)
  * Vector/SIMD unit
  * Scalar core ([Google for Developers][1])
* **C-programmable model**
* Full **hardware IP + simulator + compiler stack**
* MLIR-based toolchain (LLVM ecosystem)

👉 In other words:

> it’s not just “run model → magic happens”, you can actually follow the pipeline.

---

### Architecture flavor (important for you)

Coral NPU is basically:

\`\`\`
[RISC-V scalar core]
        ↓
[Vector unit (SIMD)]
        ↓
[Matrix accelerator]
\`\`\`

* Control runs on RISC-V
* Heavy lifting goes to tensor/matrix blocks
* Very similar to how you'd design a custom accelerator yourself

---

### ISA situation (this is the interesting part)

It’s not a clean “here is a sexy standalone NPU ISA PDF” like old-school CPUs.

Instead:

* Base = **RISC-V ISA (RV32 + vector extensions)** ([verisilicon.com][2])
* Plus:

  * Custom tensor/matrix instructions
  * Compiler lowers ML ops → these instructions via MLIR

👉 So the *real ISA* is:

> RISC-V + hidden-but-visible-through-compiler tensor ops

---

### How deep can you go?

Pretty deep actually:

* HDL (Chisel/Verilog-ish) exists
* Cycle-accurate simulator exists ([Google for Developers][3])
* You can trace:

  * kernel → MLIR → lowered ops → execution

That’s rare territory for NPUs.

---

# 🧪 2. Semi-open NPUs (less satisfying, but useful)

## Qualcomm Hexagon NPU

* Not open hardware
* But:

  * MLIR-based compiler stack is partially open
  * You can see how kernels map to hardware ([arXiv][4])

👉 Good for:

* Understanding scheduling + memory layout
* Not good for ISA spelunking

---

## Intel NPU (Meteor Lake / VPU)

* Kernel drivers + some libs open
* Instruction set: ❌ hidden
* Programming: via OpenVINO / runtime

👉 Feels like:

> “You may look at the steering wheel, but not the engine”

---

# 🧪 3. Actually open (but experimental / chaotic)

There are small community projects like:

* custom FPGA NPUs
* research repos with systolic arrays
* hobbyist “NPU arrays”

From Reddit (summarized reality check):

> “not tapeout ready… more like a hardware plan” ([Reddit][5])

👉 Translation:

* Great for ideas
* Not great for stable docs or ISA

---

# 🧠 What’s *missing* (and why it’s frustrating)

Unlike CPUs or GPUs, NPUs rarely expose:

* Stable ISA docs
* Assembly-level programming
* Vendor-neutral standards

Why?

Because:

> NPUs are **compiler-driven machines**, not programmer-driven ones.

So vendors expose:

* Graph compilers
* IR (MLIR, ONNX, etc.)

instead of:

* “write assembly for this tensor core”

---

# ⚡ The real takeaway

If you want to **study an NPU like you’d study a CPU or GPU**, your best bet is:

👉 **Coral NPU**

Everything else is:

* either too proprietary
* or too experimental

---

# 🧩 If you want something *even closer to metal*

Given your interests (RISC-V, low-level, custom compute):

You might actually enjoy:

* Designing your own:

  * systolic array
  * or vector + MAC pipeline
* Using:

  * RISC-V vector extension (RVV)
  * * custom instructions

Because ironically:

> the fastest way to understand NPUs deeply
> is to build a tiny one yourself 😄

---

If you want, I can:

* walk through Coral’s pipeline (MLIR → execution)
* or sketch a minimal NPU ISA you could implement on FPGA / simulator (this gets fun fast)

[1]: https://developers.google.com/coral/guides/hardware/datasheet?utm_source=chatgpt.com "Coral NPU datasheet  |  Google for Developers"
[2]: https://www.verisilicon.com/en/PressRelease/CoralNPU?utm_source=chatgpt.com "VeriSilicon and Google Jointly Launch Open-Source Coral NPU IP"
[3]: https://developers.google.com/coral/guides/hardware/get-started?utm_source=chatgpt.com "Overview  |  Coral  |  Google for Developers"
[4]: https://arxiv.org/abs/2602.19762?utm_source=chatgpt.com "Hexagon-MLIR: An AI Compilation Stack For Qualcomm's Neural Processing Units (NPUs)"
[5]: https://www.reddit.com/r/LocalLLM/comments/1s1hdlg/im_opensourcing_my_experimental_custom_npu/?utm_source=chatgpt.com "I'm open-sourcing my experimental custom NPU architecture designed for local AI acceleration"
        `
    }
]
