from dataclasses import dataclass
from typing import Literal


@dataclass
class ConversationMessage:
    id: str
    role: Literal["user", "assistant"]
    content: str
    timestamp: str

@dataclass
class Conversation:
    id: str
    label: str
    messages: list[ConversationMessage]

CONVERSATIONS: list[Conversation] = [
    Conversation(
        id='c1',
        label='Function "map"',
        messages=[
            ConversationMessage(id='m1', role='user', content='What does the `map` function do in functional programming?', timestamp='2026-04-22T09:00:00Z'),
            ConversationMessage(id='m2', role='assistant', content='`map` applies a given function to every element of a collection and returns a new collection with the results.\n\n**Example:**\n```python\nresult = list(map(lambda x: x*2, [1,2,3]))  # [2,4,6]\n```', timestamp='2026-04-22T09:00:05Z'),
            ConversationMessage(id='m3', role='user', content='How is `map` different from a `for` loop?', timestamp='2026-04-22T09:01:00Z'),
            ConversationMessage(id='m4', role='assistant', content='`map` is declarative: you describe the transformation, not the iteration mechanics. It composes well with other higher-order functions and can enable lazy evaluation when used with iterators.', timestamp='2026-04-22T09:01:10Z'),
            ConversationMessage(id='m5', role='user', content='Can `map` work with async functions?', timestamp='2026-04-22T09:02:00Z'),
            ConversationMessage(id='m6', role='assistant', content='Yes — with async iterables or helper utilities. For example, use `asyncio.gather` over mapped coroutines or libraries that provide `amap` for asynchronous maps.\n\n**Tip:** prefer explicit concurrency control to avoid unbounded parallelism.', timestamp='2026-04-22T09:02:10Z'),
        ],
    ),
    Conversation(
        id='c2',
        label='Monads',
        messages=[
            ConversationMessage(id='m1', role='user', content='I hear monads are scary — what is a monad?', timestamp='2026-04-22T10:00:00Z'),
            ConversationMessage(id='m2', role='assistant', content='A monad is a design pattern that represents computations as a type with two operations: `return` (or `unit`) and `bind` (often `>>=`).\n\n**Intuition:** it sequences computations while threading context (like failure, state, or I/O).', timestamp='2026-04-22T10:00:10Z'),
            ConversationMessage(id='m3', role='user', content='Can you give a concrete example?', timestamp='2026-04-22T10:01:00Z'),
            ConversationMessage(id='m4', role='assistant', content='Monads obey laws (left identity, right identity, associativity). These laws make reasoning and composition predictable.', timestamp='2026-04-22T10:02:00Z'),
        ],
    ),
    Conversation(
        id='c3',
        label='RAG System Implementation',
        messages=[
            ConversationMessage(id='m1', role='user', content='How do I implement a basic RAG (Retrieval-Augmented Generation) system?', timestamp='2026-04-22T11:00:00Z'),
            ConversationMessage(id='m2', role='assistant', content='A minimal RAG pipeline: 1) index documents with embeddings; 2) retrieve nearest passages for a query; 3) condition the generator (LLM) on retrieved context + query.\n\n**Architecture sketch:**\n- Embedder (e.g., OpenAI embeddings)\n- Vector DB (FAISS, Chroma)\n- Retriever + Reranker\n- Generator (LLM) that consumes retrieved chunks', timestamp='2026-04-22T11:00:10Z'),
            ConversationMessage(id='m3', role='user', content='What are common pitfalls?', timestamp='2026-04-22T11:01:00Z'),
            ConversationMessage(id='m4', role='assistant', content='Pitfalls: stale or inconsistent retrieval, hallucinations from the generator, and not controlling context length. Use chunking, relevance scoring, and prompt templates to reduce errors.\n\n**Prompt hint:** include citations from sources and ask the model to quote passage IDs.', timestamp='2026-04-22T11:01:20Z'),
            ConversationMessage(id='m5', role='user', content='Any quick code pointers?', timestamp='2026-04-22T11:02:00Z'),
            ConversationMessage(id='m6', role='assistant', content='Start with an embeddings client, index with small chunk size (~500 tokens), and validate retrieval quality before wiring up the generator.\n\nIf you want, I can provide a tiny Python starter that uses FAISS + OpenAI embeddings.', timestamp='2026-04-22T11:02:10Z'),
        ],
    ),
    Conversation(
        id='c4',
        label='Lambda Calculus Basics',
        messages=[
            ConversationMessage(id='m1', role='user', content='What is lambda calculus?', timestamp='2026-04-22T12:00:00Z'),
            ConversationMessage(id='m2', role='assistant', content='Lambda calculus is a minimal formal system for defining and applying functions. It has three constructs: variables, abstraction (\lambda x. M) and application (M N).\n\n**It is the theoretical foundation of functional programming.**', timestamp='2026-04-22T12:00:10Z'),
            ConversationMessage(id='m3', role='user', content='How do you represent booleans and numbers?', timestamp='2026-04-22T12:01:00Z'),
            ConversationMessage(id='m4', role='assistant', content='Booleans and natural numbers can be encoded (Church encodings).\n\n**Example (Church true/false):**\n```text\ntrue  = λa.λb.a\nfalse = λa.λb.b\n```\nThese let you build control flow using only functions.', timestamp='2026-04-22T12:01:20Z'),
            ConversationMessage(id='m5', role='assistant', content='Reduction strategies matter (normal vs applicative order). Normal-order reduction finds normal forms when they exist.', timestamp='2026-04-22T12:02:00Z'),
        ],
    ),
    Conversation(
        id='c5',
        label='Type Inference',
        messages=[
            ConversationMessage(id='m1', role='user', content='What is type inference?', timestamp='2026-04-22T13:00:00Z'),
            ConversationMessage(id='m2', role='assistant', content='Type inference automatically deduces types of expressions without explicit annotations. Hindley–Milner is a classic algorithm used in ML-family languages.\n\n**Result:** cleaner code with static safety.', timestamp='2026-04-22T13:00:10Z'),
            ConversationMessage(id='m3', role='user', content='How does Hindley–Milner work at a high level?', timestamp='2026-04-22T13:01:00Z'),
            ConversationMessage(id='m4', role='assistant', content='It generates type variables for expressions, emits constraints from usage, then solves them via unification to produce principal types.\n\n**Key steps:** generate constraints → unify → generalize at let-bindings.', timestamp='2026-04-22T13:01:20Z'),
            ConversationMessage(id='m5', role='assistant', content='If you want, I can show a short Python demo that performs unification for simple lambda terms.', timestamp='2026-04-22T13:02:00Z'),
        ],
    ),
    Conversation(id='c6', label="Recursion vs Iteration", messages=[]),
    Conversation(id='c7', label="Currying and Partial Application", messages=[]),
    Conversation(id='c8', label="Algebraic Data Types", messages=[]),
    Conversation(id='c9', label="Pattern Matching", messages=[]),
    Conversation(id='c10', label="Higher-Order Functions", messages=[]),
    Conversation(id='c11', label="Lazy Evaluation", messages=[]),
    Conversation(id='c12', label="Functors and Applicatives", messages=[]),
    Conversation(id='c13', label="Tail Call Optimization", messages=[]),
    Conversation(id='c14', label="List Comprehensions", messages=[]),
    Conversation(id='c15', label="State Monad", messages=[]),
    Conversation(id='c16', label="Fold and Unfold", messages=[]),
    Conversation(id='c17', label="Point-Free Style", messages=[]),
    Conversation(id='c18', label="Category Theory Intro", messages=[]),
    Conversation(id='c19', label="Dependent Types", messages=[]),
    Conversation(id='c20', label="Pure Functions and Side Effects", messages=[]),
    Conversation(id='c21', label="Continuation Passing Style", messages=[]),
    Conversation(id='c22', label="Memoization Techniques", messages=[]),
    Conversation(id='c23', label="Zipper Data Structure", messages=[]),
]
