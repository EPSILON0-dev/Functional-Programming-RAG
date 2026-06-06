# PF-RAG: Intelligent Functional Programming Chatbot

## What This App Does

**PF-RAG** is a **Retrieval-Augmented Generation (RAG) chatbot** designed to help students learn **Programowanie Funkcyjne** (Functional Programming) by answering course-related questions with intelligent context-awareness. 

The system combines:
- A **knowledge base of course materials** (stored as vector embeddings in PostgreSQL with pgvector)
- A **sophisticated 6-stage LLM pipeline** that analyzes queries, retrieves relevant materials, and generates accurate responses
- A **modern chat interface** with real-time updates and persistent conversation history
- **User account management** with encrypted API key storage for LLM providers

Unlike simple chatbots, PF-RAG uses an intelligent pipeline that validates whether knowledge base lookup is needed, generates baseline answers, retrieves relevant materials, and validates the final response for accuracy.

---

## What It Can Do

### **Chat & Conversation**
- Create multiple persistent chat conversations with automatic history tracking
- Send messages and receive AI-generated responses in real-time
- Rename and delete conversations
- View full chat history with metadata (generation costs, timestamps)

### **Knowledge Base Integration**
- Browse the complete knowledge base of Functional Programming course materials
- Automatically retrieve relevant articles based on vector similarity search
- Dual search: semantic search on both article content and descriptions
- View article details, relationships, and coverage in responses

### **Intelligent Pipeline**
The 6-stage response generation ensures high-quality, context-aware answers:
1. **Topic Extraction** — Determines if knowledge base lookup is needed and normalizes the query
2. **Uninformed Response** — Generates a baseline answer for comparison
3. **Retrieval** — Performs vector similarity search against the knowledge base
4. **Reranking** — Evaluates article relevance
5. **Generation** — Creates final response with retrieved context
6. **Response Validation** — Validates and potentially refines the generated response

### **Account & Configuration**
- User registration and authentication with JWT tokens
- API key management (support for OpenRouter and Ollama LLM providers)
- Encrypted API key storage with key rotation support
- Account settings: username change, password updates
- Per-conversation model/parameter configuration

### **Real-Time Updates**
- WebSocket-based live message streaming
- Real-time progress updates showing which pipeline stage is executing
- See "generating" status while the AI processes your query

---

## How It Works

### **User Interaction Flow**

```
User (Frontend)
    ↓ Types message and clicks send
    ↓ POST /api/chats/{id}/messages
Backend Server (Phoenix)
    ↓ Validates authentication (JWT token)
    ↓ Saves user message to database
    ↓ Enqueues async job (Oban background worker)
    ↓ Returns 202 Accepted (request received)
    ↓
Background Worker (Async Job Queue)
    ↓ Executes 6-stage RAG pipeline
    ├─ Stage 1: Topic extraction & analysis
    ├─ Stage 2: Generate uninformed baseline
    ├─ Stage 3: Retrieve relevant articles (vector search)
    ├─ Stage 4: Rerank for relevance
    ├─ Stage 5: Generate contextual response
    └─ Stage 6: Validate response quality
    ↓ Saves AI response to database
    ↓
WebSocket Connection
    ↓ Sends real-time updates to connected client
Frontend (React)
    ↓ AppContext state receives new message
    ↓ ChatView re-renders with response
    ↓ Message appears in conversation
```

### **Key Design Principles**

**Asynchronous Processing**: Heavy LLM operations run in background workers (Oban), preventing HTTP timeouts and keeping the UI responsive. Users see real-time progress updates via WebSocket.

**Vector + Keyword Search**: Articles are retrieved using vector similarity on both content and descriptions (HyDE - Hypothetical Document Embedding), ensuring better coverage of relevant materials.

**Cost Tracking**: Every LLM API call is tracked and logged with associated costs, enabling monitoring and billing accuracy.

**Real-Time Feedback**: WebSocket connections stream progress updates, allowing users to see which pipeline stage is currently executing.

**Encrypted Credentials**: Users provide their own LLM provider API keys, which are encrypted before storage using the Cloak library.

---

## Architecture

### **System Overview**

PF-RAG follows a **classic full-stack architecture**:

```
┌─────────────────────────────┐
│   React TypeScript UI       │
│   (Vite, React Router)      │
│   • ChatView                │
│   • DatabaseView            │
│   • AuthView                │
└──────────────┬──────────────┘
               │ HTTP REST API
               │ + WebSocket
               ↓
┌──────────────────────────────────┐
│   Phoenix/Elixir Backend         │
│   ┌────────────────────────────┐ │
│   │ HTTP Controllers/Channels  │ │
│   ├────────────────────────────┤ │
│   │ Business Logic (Contexts)  │ │
│   │ • Chat, Message, Article   │ │
│   │ • User, APIKey             │ │
│   ├────────────────────────────┤ │
│   │ 6-Stage RAG Pipeline       │ │
│   │ • Topic extraction         │ │
│   │ • Retrieval/Reranking      │ │
│   │ • Generation               │ │
│   ├────────────────────────────┤ │
│   │ Job Queue (Oban)           │ │
│   │ Async message processing   │ │
│   ├────────────────────────────┤ │
│   │ LLM Provider Integration   │ │
│   │ • OpenRouter API           │ │
│   │ • Ollama local models      │ │
│   └────────────────────────────┘ │
└──────────────┬───────────────────┘
               │ SQL / Vector Ops
               ↓
┌──────────────────────────────┐
│   PostgreSQL Database        │
│   ┌────────────────────────┐ │
│   │ Tables:                │ │
│   │ • users (accounts)     │ │
│   │ • api_keys (encrypted) │ │
│   │ • chats (conversations)│ │
│   │ • messages (history)   │ │
│   │ • articles (KB)        │ │
│   └────────────────────────┘ │
│   ┌────────────────────────┐ │
│   │ pgvector Extension     │ │
│   │ Vector embeddings      │ │
│   │ Similarity search      │ │
│   └────────────────────────┘ │
└──────────────────────────────┘
```

### **Backend Architecture (Phoenix/Elixir)**

The backend follows **Elixir/Phoenix best practices**:

**1. Context Layer** (`lib/api/`):
- Business logic separated into bounded contexts
- No direct database queries in controllers
- Contexts: `Chat`, `Message`, `Article`, `User`, `APIKey`
- Each context handles CRUD operations and domain queries

**2. Web Layer** (`lib/api_web/`):
- **Controllers**: REST endpoints that delegate to contexts
  - `ChatController` — Chat CRUD, message creation, pipeline triggering
  - `UserController` — Registration, authentication, account settings
  - `ArticleController` — Knowledge base browsing
  - `APIKeyController` — API key management
- **Channels**: WebSocket communication
  - `UserChannel` — Real-time message and progress updates
- **Authentication**: JWT tokens validated via plugs in `auth.ex`

**3. Pipeline Layer** (`lib/pipeline/`):
- **Generation Pipeline** (`lib/pipeline/generation/`):
  - 6-stage LLM processing chain
  - Each stage is a separate module for testability and maintainability
  - Stages: `TopicExtraction`, `UninformedResponse`, `Retrieval`, `Rerank`, `Generation`, `ResponseRerank`
- **Loading Pipeline** (`lib/pipeline/loading/`):
  - Document processing (PDF/Word → Markdown)
  - Embedding generation and indexing
- **Utilities** (`lib/pipeline/misc/`):
  - Shared functions, prompt templates, formatting

**4. Job Queue** (`lib/api/jobs/`):
- **Oban Integration**: Background job processing
- `RunPipelineJob` — Executes the 6-stage pipeline asynchronously
- Jobs store progress and update frontend via WebSocket

**5. LLM Integration** (`lib/provider/`):
- **OpenRouter Client** (`provider/openrouter.ex`):
  - HTTP wrapper around OpenRouter API
  - Supports model selection, parameter tuning, cost tracking
- **Ollama Support**:
  - Local LLM inference option
  - Alternative to cloud-based OpenRouter

**6. OTP Application** (`lib/api/application.ex`):
- Supervisor tree defining child processes
- Oban job queue supervisor
- Database connection pool configuration

### **Frontend Architecture (React + TypeScript)**

The frontend is a **modern React 19 + TypeScript application**:

**1. State Management** (`AppContext.tsx`):
- **Global State** managed via `useReducer`:
  - Current user profile
  - List of chats (conversations)
  - Current chat messages
  - UI state (theme, modal visibility)
  - Articles (knowledge base)
- **Actions**: UPDATE_CHATS, ADD_MESSAGE, SET_USER, RENAME_CHAT, etc.
- Single source of truth for all app state

**2. Views (Pages)** (`src/views/`):
- **ChatView**: Main chat interface
  - Message list (scrollable history)
  - Message input with pipeline config
  - Sidebar with chat list
  - Real-time message updates
- **NewChatView**: Create new conversation
  - Form to start first message
  - Model/parameter selection
- **DatabaseView**: Knowledge base explorer
  - Browse articles
  - View article details
  - Search/filter
- **AuthView**: Login/registration
  - Form validation
  - Error handling
  - JWT token management

**3. Components** (`src/components/`):
- **ChatInput**: Message input box with formatting
- **Messages**: Message list with rendering for:
  - User messages (right-aligned)
  - Assistant messages (left-aligned)
  - Generating state (animated indicator)
- **PipelineConfigModal**: Model/temperature/token selection
- **AccountSettings**: Profile editing
- **ApiKeySettings**: LLM provider key management
- **UI Components** (`src/components/ui/`):
  - Base components using Sonner toasts, TailwindCSS styling
  - Button, Card, Form inputs (composed from shadcn/ui patterns)

**4. Hooks** (`src/hooks/`):
- Custom React hooks for reusable logic
- Examples: `useChat()`, `useFetch()`, etc.

**5. Utilities** (`src/lib/`):
- **auth.ts**: API calls for login/register/account operations
- **ws.ts**: WebSocket manager with auto-reconnection and heartbeat
- **utils.ts**: Helper functions (date formatting, text truncation, etc.)

**6. TypeScript Definitions** (`src/types/types.ts`):
- Interfaces for domain models:
  - `Message` — Chat message with role, content, metadata
  - `Conversation` — Chat session with messages
  - `Article` — Knowledge base article with embeddings
  - `User` — User profile with API keys

**7. Routing** (`App.tsx`):
- React Router v7 setup
- Routes:
  - `/` — Chat list or redirect to latest chat
  - `/chat/:chatId` — Chat interface for specific conversation
  - `/database/:databaseId` — Knowledge base view
  - `/auth` — Login/register page
- Auth gate: redirects unauthenticated users to `/auth`

---

## Code Structure

### **Backend Structure** (`api/lib/`)

```
api/lib/
│
├── api.ex                          # Main entry point
├── api_web.ex                      # Web layer entry point
│
├── api/                            # Business logic contexts
│   ├── chat.ex                     # Chat CRUD + queries
│   ├── message.ex                  # Message CRUD, retrieval
│   ├── article.ex                  # Article storage, search
│   ├── user.ex                     # User registration, auth
│   ├── apikey.ex                   # Encrypted API key storage
│   ├── application.ex              # OTP supervisor tree
│   └── repo.ex                     # Ecto repository
│
├── api_web/                        # Web layer
│   ├── controllers/                # HTTP request handlers
│   │   ├── user_controller.ex      # Auth, account endpoints
│   │   ├── chat_controller.ex      # Chat, message endpoints
│   │   └── article_controller.ex   # Knowledge base endpoints
│   ├── channels/                   # WebSocket handlers
│   │   └── user_channel.ex         # Real-time updates
│   ├── sockets/                    # WebSocket config
│   │   └── user_socket.ex          # Connection setup
│   ├── auth.ex                     # Authentication plug
│   ├── token.ex                    # JWT token generation
│   └── router.ex                   # Route definitions
│
├── pipeline/                       # RAG pipeline implementation
│   ├── generation/                 # LLM processing stages
│   │   ├── topic_extraction.ex    # Stage 1: Extract topic
│   │   ├── uninformed_response.ex # Stage 2: Baseline answer
│   │   ├── retrieval.ex           # Stage 3: Vector search
│   │   ├── rerank.ex              # Stage 4: Rerank articles
│   │   ├── generation.ex          # Stage 5: Generate response
│   │   └── response_rerank.ex     # Stage 6: Validate response
│   ├── loading/                    # Document processing
│   │   ├── article_loader.ex      # Load & index articles
│   │   └── embeddings.ex          # Generate embeddings
│   └── misc/                       # Utilities & templates
│       ├── prompts.ex             # LLM prompt templates
│       └── formatting.ex          # Text/markdown utilities
│
├── provider/                       # LLM provider integration
│   ├── openrouter.ex              # OpenRouter API client
│   └── ollama.ex                  # Ollama local inference
│
└── jobs/                           # Oban background workers
    └── run_pipeline_job.ex         # Execute RAG pipeline
```

### **Frontend Structure** (`ui/src/`)

```
src/
│
├── main.tsx                        # Application entry point
├── App.tsx                         # Root component, routing
├── App.css                         # Global styles
├── AppContext.tsx                  # Global state + reducer
│
├── views/                          # Page-level components
│   ├── ChatView.tsx               # Main chat interface
│   ├── NewChatView.tsx            # Chat creation
│   ├── DatabaseView.tsx           # Knowledge base explorer
│   ├── AuthView.tsx               # Login/register
│   └── NavSidebar.tsx             # Navigation sidebar
│
├── components/                     # Reusable components
│   ├── ChatInput.tsx              # Message input with config
│   ├── Messages.tsx               # Message display list
│   ├── PipelineConfigModal.tsx    # Model/parameter selection
│   ├── AccountSettings.tsx        # Profile settings
│   ├── ApiKeySettings.tsx         # API key management
│   └── ui/                        # Base UI components
│       ├── Button.tsx
│       ├── Card.tsx
│       ├── Modal.tsx
│       └── ... (shadcn/ui components)
│
├── hooks/                          # Custom React hooks
│   └── ... (useChat, useFetch, etc.)
│
├── lib/                            # Utility functions
│   ├── auth.ts                     # Auth API calls
│   ├── ws.ts                       # WebSocket manager
│   └── utils.ts                    # Helper functions
│
├── types/                          # TypeScript definitions
│   └── types.ts                    # Domain models & interfaces
│
├── assets/                         # Static assets
│   └── ... (images, fonts)
│
└── index.css                       # TailwindCSS imports
```

### **Database Schema** (PostgreSQL)

Key tables managed by Ecto:

- **users**: User accounts, password hashes
- **api_keys**: Encrypted LLM provider API keys
- **chats**: Conversation sessions
- **messages**: Chat history with embeddings (pgvector)
- **articles**: Knowledge base articles with embeddings (pgvector)

The schema is defined in Ecto migrations under `api/priv/repo/migrations/`.

---

## Tech Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Frontend Framework** | React | 19.2 | UI library |
| | TypeScript | 6.0 | Type safety |
| | Vite | 8.0 | Build tool & dev server |
| **Frontend Routing** | React Router | 7.14 | Client-side navigation |
| | TailwindCSS | 4.2 | Utility-first CSS styling |
| **Frontend State** | React Hooks + Context | — | useReducer for global state |
| | Sonner | 2.0 | Toast notifications |
| **Backend Framework** | Phoenix | 1.8.5 | Web framework |
| | Elixir | 1.15 | Language runtime |
| **Database & ORM** | Ecto | 3.13 | ORM & query builder |
| | PostgreSQL | 14+ | Primary database |
| **Vector Search** | pgvector | 0.3 | Vector similarity in SQL |
| **Authentication** | bcrypt_elixir | 3.0 | Password hashing |
| | joken | 2.6.2 | JWT token generation/validation |
| **Background Jobs** | Oban | 2.17 | Job queue & scheduler |
| **LLM Integration** | OpenRouter API / Ollama | — | Model inference endpoints |
| **Encryption** | Cloak | — | Sensitive data at-rest encryption |
| **HTTP Client** | Finch | — | HTTP requests (Phoenix framework) |
| **Document Processing** | PyMuPDF / Pandoc | — | PDF/Word → Markdown conversion |

---

## Key Workflows

### **Message Sending Workflow**

1. **User types message** in ChatView and clicks send
2. **Frontend validates**:
   - Message not empty
   - User authenticated (valid JWT)
   - Chat ID valid
3. **HTTP POST** to `/api/chats/{chatId}/messages`
   - Body: `{ content: "...", model: "...", temperature: 0.7, ... }`
4. **Backend**:
   - Validates JWT token via auth plug
   - Creates Message record (role: "user")
   - Enqueues `RunPipelineJob` (Oban)
   - Returns `202 Accepted` immediately
5. **Async Job Execution**:
   - Worker executes 6-stage pipeline
   - Broadcasts progress via WebSocket: `pipeline:progress` event
   - Creates Message record for AI response (role: "assistant")
   - Broadcasts new message via WebSocket: `message:new` event
6. **Frontend WebSocket Listener**:
   - Receives real-time updates
   - Updates AppContext state
   - ChatView re-renders with new messages

### **User Registration Workflow**

1. **User enters credentials** in AuthView
2. **Frontend POST** to `/api/auth/register`
   - Body: `{ email: "...", username: "...", password: "..." }`
3. **Backend**:
   - Validates input (unique email, username length, password strength)
   - Hashes password with bcrypt_elixir
   - Creates User record
   - Returns JWT token + user profile
4. **Frontend**:
   - Stores JWT in localStorage/sessionStorage
   - Sets AppContext user state
   - Redirects to chat view

### **Knowledge Base Retrieval Workflow**

1. **Pipeline Stage 3 (Retrieval)**:
   - Receives user query
   - Generates query embedding (via LLM provider)
   - Performs pgvector similarity search:
     - Find articles by content embedding: `<=> embedding`
     - Find articles by description embedding (HyDE)
     - Union and rank by relevance score
   - Returns top-k articles
2. **Stage 4 (Rerank)**:
   - Re-evaluates retrieved articles using LLM
   - Scores for relevance to query
   - Returns re-ranked list
3. **Stage 5 (Generation)**:
   - Passes query + retrieved articles to LLM
   - LLM generates response with citations
   - Formats response with markdown

### **Delete Message Workflow**

1. **User clicks delete icon** on a message in ChatView
2. **Frontend HTTP DELETE** to `/api/chats/{chatId}/messages/{messageId}`
3. **Backend**:
   - Validates JWT token via auth plug
   - Validates user owns the chat
   - Soft-deletes message (sets `deleted_at` timestamp)
   - Returns `204 No Content`
   - Broadcasts WebSocket event to all user connections: `message_deleted` with `{message_id, chat_id}`
4. **Frontend WebSocket Listener**:
   - Receives `message_deleted` event
   - Updates AppContext state (removes message from list)
   - ChatView re-renders, message disappears from conversation

### **Retry Generation Workflow**

1. **Pipeline fails** and returns error message (role: "error") to user
   - Message displays error content with error icon
2. **User clicks retry button** on the error message
3. **Frontend HTTP POST** to `/api/chats/{chatId}/retry`
   - Body: `{ config: {...} }` - same config object as normal message send
4. **Backend**:
   - Validates JWT token and chat ownership
   - Validates no generation is currently running (checks ProgressTracker)
   - Gets last message in the chat
   - Validates it's an error message (role == "error")
   - Soft-deletes the error message (sets `deleted_at` timestamp)
   - Broadcasts `message_deleted` WebSocket event
   - Finds the previous user message (the original question)
   - Enqueues new `RunPipelineJob` using that user message
   - Returns `200 OK` with "Retry generation started"
5. **Async Job Execution**:
   - Same as normal message send: 6-stage pipeline execution
   - Broadcasts progress and new response via WebSocket
6. **Frontend WebSocket Listeners**:
   - Receives `message_deleted` event (error message disappears)
   - Receives `pipeline_progress` events (shows loading stages)
   - Receives `response_new` and `response_complete` events (new response appears)

---

## Outstanding Work Items (TODOs)

From [TODO.md](TODO.md):
- Fix generating message animation glitches
- Add more LLM model options
- Redesign home/landing page (current AuthView is outdated)
- Add message information panel (references, model used, generation cost)
- Improve Markdown rendering of AI responses
- Add context length limit handling for long conversations
- Set up Docker containerization
- Create database seeding scripts for demo data

---

## Getting Started

### **Prerequisites**
- Elixir 1.15+
- Phoenix 1.8+
- PostgreSQL 14+
- Node.js 18+
- npm or yarn

### **Backend Setup**
```bash
cd api
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```
Server runs on `http://localhost:4000`

### **Frontend Setup**
```bash
cd ui
npm install
npm run dev
```
Dev server runs on `http://localhost:5173`

### **Configuration**
- Backend config: `api/config/dev.exs` (database, ports, secrets)
- Frontend config: `ui/vite.config.ts`
- Environment variables: `.env` files or system environment

---

## API Overview

### **Authentication Endpoints**
```
POST   /api/auth              # Login
POST   /api/auth/register     # Register
GET    /api/auth/me           # Get current user
PATCH  /api/auth/me/username  # Change username
PATCH  /api/auth/me/password  # Change password
```

### **Chat Endpoints**
```
GET    /api/chats                      # List user's chats
POST   /api/chats                      # Create new chat
POST   /api/chats/new                  # Create chat + first message
GET    /api/chats/:id                  # Get chat metadata
GET    /api/chats/:id/messages         # Get all messages
POST   /api/chats/:id/messages         # Send message (triggers pipeline)
POST   /api/chats/:id/rename           # Rename chat
POST   /api/chats/:id/retry            # Retry generation on error message
DELETE /api/chats/:id                  # Delete chat
DELETE /api/chats/:id/messages/:msg_id # Delete a specific message
```

### **Knowledge Base Endpoints**
```
GET    /api/articles          # List all articles
GET    /api/articles/:id      # Get article details
```

### **API Key Management**
```
GET    /api/auth/keys         # List user's API keys
POST   /api/auth/keys         # Add new API key
DELETE /api/auth/keys/:id     # Remove API key
```

### **WebSocket**
```
ws://localhost:4000/api/websocket?token={jwt_token}

Topics:
  user:{user_id}:chat:{chat_id}

Events:
  message:new              # New message from pipeline
  message_deleted          # Message was deleted (includes message_id, chat_id)
  pipeline:progress        # Pipeline stage update
  chat:renamed             # Chat name changed
```

---

## Important Notes

**Real-Time Updates**: The frontend maintains a persistent WebSocket connection per chat. When you send a message, the backend enqueues a background job and immediately responds. The background worker then publishes updates via WebSocket in real-time.

**Cost Tracking**: Every LLM API call is logged with associated costs. This enables monitoring API spending and potential billing/quota management.

**Encrypted Keys**: User-provided LLM API keys are encrypted before storage using Cloak. Keys are only decrypted when needed for API calls.

**Vector Search**: Articles are indexed with embeddings. Retrieval uses pgvector's `<=>` operator for fast similarity search. Both article content and descriptions are indexed for better coverage.

**Stateless Backend**: The backend is designed to be stateless for horizontal scaling. All state lives in the database or is transmitted via WebSocket. This makes deployment to multiple servers straightforward.

---

## Related Documentation

- Backend: [api/README.md](api/README.md)
- Frontend: [ui/README.md](ui/README.md)
- Outstanding tasks: [TODO.md](TODO.md)
