from dataclasses import dataclass

@dataclass
class DatabaseDocument:
    id: str
    title: str
    abstract: str
    content: str

@dataclass
class Database:
    id: str
    label: str
    documents: list[DatabaseDocument]


haskell_db = Database(
    id="db1",
    label="Haskell",
    documents=[
        DatabaseDocument(
            id="haskell-1",
            title="Introduction to Haskell",
            abstract="An overview of Haskell as a purely functional, statically typed programming language with lazy evaluation.",
            content="Haskell is a purely functional programming language with strong static typing and lazy evaluation. It was designed in the late 1980s by a committee of researchers who wanted a common language for functional programming research. Haskell programs are built from functions that take inputs and return outputs without side effects. All side effects, such as I/O, are managed through monads, which provide a way to sequence effectful computations within the pure functional model. Haskell's type system, based on Hindley-Milner type inference, allows the compiler to deduce types automatically in most cases, reducing annotation burden while ensuring type safety.",
        ),
        DatabaseDocument(
            id="haskell-2",
            title="Haskell Type Classes",
            abstract="A deep dive into Haskell's type class system, enabling ad-hoc polymorphism and generic programming.",
            content="Type classes in Haskell provide a mechanism for defining generic interfaces that types can implement. Unlike object-oriented interfaces, type classes in Haskell are resolved at compile time, producing zero-cost abstractions. Common type classes include Eq for equality, Ord for ordering, Show for string conversion, and Functor, Applicative, and Monad for abstracting over computational contexts. Type class instances can be derived automatically by the compiler for many standard classes. The newtype deriving and GeneralizedNewtypeDeriving extensions allow instances to be inherited through newtype wrappers, reducing boilerplate significantly.",
        ),
        DatabaseDocument(
            id="haskell-3",
            title="Monads in Haskell",
            abstract="An explanation of monads as an abstraction for sequencing computations with effects in Haskell.",
            content="A monad in Haskell is a type class with two core operations: return, which wraps a value in a monadic context, and bind (>>=), which sequences monadic computations by passing the result of one computation into the next. Common monads include Maybe for optional values, Either for error handling, IO for input/output, State for stateful computations, and Reader for dependency injection. The do-notation provides syntactic sugar that makes monadic code look like imperative code while retaining pure functional semantics. Monad transformers such as StateT and ReaderT allow multiple monadic effects to be combined in a stack.",
        ),
        DatabaseDocument(
            id="haskell-4",
            title="Lazy Evaluation in Haskell",
            abstract="How Haskell's lazy evaluation strategy defers computation and enables infinite data structures.",
            content="Haskell uses lazy evaluation, also called call-by-need, meaning expressions are not evaluated until their value is required. This strategy allows programs to work with potentially infinite data structures such as infinite lists, because only the portion actually needed is computed. For example, the expression `take 10 [1..]` produces the first ten natural numbers without evaluating the entire infinite list. Laziness can improve performance by avoiding unnecessary computation, but it can also lead to space leaks if large unevaluated thunks accumulate in memory. The seq function and bang patterns force strict evaluation where needed to control memory usage.",
        ),
    ],
)

javascript_db = Database(
    id="db2",
    label="JavaScript",
    documents=[
        DatabaseDocument(
            id="js-1",
            title="JavaScript Fundamentals",
            abstract="A primer on JavaScript's core features including dynamic typing, prototypal inheritance, and event-driven execution.",
            content="JavaScript is a dynamically typed, interpreted programming language originally designed for scripting web pages in browsers. It supports multiple programming paradigms including imperative, object-oriented, and functional styles. JavaScript uses prototypal inheritance rather than classical class-based inheritance, though ES6 introduced class syntax as syntactic sugar over prototypes. The language is single-threaded and uses an event loop to handle asynchronous operations such as network requests and timers without blocking execution. Variables declared with var are function-scoped and hoisted, while let and const introduced in ES6 provide block scoping and immutability respectively.",
        ),
        DatabaseDocument(
            id="js-2",
            title="Asynchronous JavaScript: Promises and async/await",
            abstract="An overview of JavaScript's asynchronous programming model using Promises and the async/await syntax.",
            content="JavaScript handles asynchronous operations through callbacks, Promises, and the async/await syntax. A Promise represents a value that may be available now, in the future, or never, and provides then and catch methods for chaining success and error handlers. The async/await syntax, introduced in ES2017, allows asynchronous code to be written in a style that resembles synchronous code, improving readability. An async function always returns a Promise, and the await keyword pauses execution of the function until the awaited Promise settles. Error handling in async functions uses standard try/catch blocks, making it consistent with synchronous error handling patterns.",
        ),
        DatabaseDocument(
            id="js-3",
            title="JavaScript Closures and Scope",
            abstract="Understanding closures, lexical scoping, and how JavaScript manages variable access across function boundaries.",
            content="A closure in JavaScript is a function that retains access to the variables of its enclosing lexical scope even after that scope has finished executing. This behavior arises from JavaScript's lexical scoping rules, where the scope of a variable is determined by its position in the source code rather than the call stack. Closures are commonly used to create private state, implement the module pattern, and produce factory functions. Each call to a function creates a new closure with its own captured environment. The IIFE (Immediately Invoked Function Expression) pattern exploits closures to encapsulate code and avoid polluting the global scope.",
        ),
        DatabaseDocument(
            id="js-4",
            title="JavaScript Modules: ES Modules and CommonJS",
            abstract="A comparison of ES Modules and CommonJS as the two primary module systems in the JavaScript ecosystem.",
            content="JavaScript has two dominant module systems: CommonJS, used by Node.js, and ES Modules (ESM), standardized in ES2015. CommonJS uses require() to import modules synchronously and module.exports to export values, making it suitable for server-side environments. ES Modules use import and export statements, support static analysis by bundlers, and enable tree-shaking to eliminate unused code. ESM imports are live bindings to the exported values rather than copies, which means changes to an exported variable are reflected in the importing module. Modern Node.js supports both systems, but mixing them requires care due to differences in how they handle circular dependencies and top-level await.",
        ),
    ],
)

functional_programming_db = Database(
    id="db3",
    label="Functional Programming",
    documents=[
        DatabaseDocument(
            id="fp-1",
            title="Core Principles of Functional Programming",
            abstract="An introduction to the foundational concepts of functional programming including pure functions, immutability, and referential transparency.",
            content="Functional programming is a programming paradigm that treats computation as the evaluation of mathematical functions and avoids changing state or mutable data. Its core principles include pure functions, which always produce the same output for the same input and have no side effects; immutability, where data structures are never modified after creation; and referential transparency, which allows any expression to be replaced with its value without changing the program's behavior. These properties make programs easier to reason about, test, and parallelize. Languages such as Haskell, Erlang, and Clojure are designed around functional principles, while languages like JavaScript, Python, and Scala support functional programming alongside other paradigms.",
        ),
        DatabaseDocument(
            id="fp-2",
            title="Higher-Order Functions and Function Composition",
            abstract="How higher-order functions and function composition enable expressive and reusable abstractions in functional programming.",
            content="A higher-order function is a function that takes one or more functions as arguments or returns a function as its result. Common higher-order functions include map, which applies a function to every element of a collection; filter, which selects elements satisfying a predicate; and fold (also called reduce), which accumulates a result by applying a binary function across a collection. Function composition combines two or more functions into a new function where the output of one becomes the input of the next, enabling pipelines of transformations. Partial application and currying are related techniques that transform multi-argument functions into chains of single-argument functions, increasing reusability and enabling point-free programming style.",
        ),
        DatabaseDocument(
            id="fp-3",
            title="Immutability and Persistent Data Structures",
            abstract="The role of immutability in functional programming and how persistent data structures enable efficient immutable operations.",
            content="Immutability means that once a data structure is created, it cannot be changed. Instead of mutating an existing structure, functional programs create new structures that share as much of the original data as possible, a technique known as structural sharing. Persistent data structures implement this sharing efficiently, allowing operations such as insertion and deletion to run in O(log n) time while preserving previous versions of the structure. Examples include persistent balanced trees and hash array mapped tries (HAMTs), which underpin immutable maps and sets in languages like Clojure and libraries like Immutable.js. Immutability eliminates entire classes of bugs related to shared mutable state and makes concurrent programs safer by removing the need for locks.",
        ),
        DatabaseDocument(
            id="fp-4",
            title="Functors, Applicatives, and Monads",
            abstract="An accessible explanation of the algebraic abstractions — functor, applicative, and monad — that structure effectful computation in functional programming.",
            content="Functors, applicatives, and monads are abstractions that describe how to apply functions to values wrapped in a computational context. A functor provides a map operation that applies a function to the wrapped value while preserving the structure of the context. An applicative functor extends this with the ability to apply a wrapped function to a wrapped value, enabling independent effects to be combined. A monad further extends applicative with a bind operation that allows the result of one computation to determine the next computation, enabling sequential, dependent effects. These abstractions appear in virtually every functional language: as type classes in Haskell, as protocols in Clojure, and as conventions in functional JavaScript libraries such as Ramda and fp-ts.",
        ),
    ],
)


DATABASES: list[Database] = [haskell_db, javascript_db, functional_programming_db]
