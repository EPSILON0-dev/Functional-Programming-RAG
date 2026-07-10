# Functional Programming Course Chatbot

> 🎓 Created for the "Functional Programming" university course.

An assistant supporting learning of the _Functional Programming_ course, based on **Retrieval-Augmented Generation (RAG)** — an approach combining knowledge base search with text generation by language models.

## Features

### **Chat and Conversations**
- Creating multiple independent conversations with automatic history saving
- Sending messages and receiving AI responses in real-time
- Renaming and deleting conversations
- Full chat history with metadata (generation costs, timestamps)

### **Knowledge Base Integration**
- Browsing the complete knowledge base of Functional Programming course materials
- Automatic search for relevant articles based on vector similarity
- Displaying article details and their usage in responses

### **User Accounts and Configuration**
- User registration and authentication with JWT tokens
- API key management for model providers (OpenRouter)
- Account settings: changing username, password
- Model and parameter configuration for individual conversations

### **Real-time Updates**
- WebSocket communication with live message streaming
- Real-time pipeline stage monitoring
- "Generating" status view during query processing

## Quick Start

#### 1. Building and Running the Application

Execute the following commands to build Docker images and run the entire application:

```bash
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up -d
```

The application will be available at **http://localhost:80**

#### 2. Account and API Configuration

Next, in the web application:

1. **Create an account** — Register a new user account
2. **Log in** — Sign in to your newly created account
3. **Go to API Key settings** — Click the account icon in the bottom left corner and select "API Keys"
4. **Add API Key** — Add your API key for the model provider (OpenRouter)
5. **Activate the key** — Select the added API key as active

Done! You can now start using the chatbot.

## Retrieval-Augmented Generation Pipeline

1. **Topic Extraction** (`1_topic_extraction.ex`)
   * Determines if knowledge base search is required
   * Normalizes the query to be context-independent
   * Returns: `{needs_kb, topic}`

2. **Uninformed Response** (`2_uninformed_response.ex`)
   * Generates a base response without access to the knowledge base
   * Used for comparison with the knowledge base-enhanced response

3. **Information Retrieval** (`3_retrieval_stage.ex`)
   * Generates embeddings for the query
   * Performs vector search for similar articles
   * Uses embeddings of both content and descriptions

4. **Result Reranking** (`4_rerank_stage.ex`)
   * Re-evaluates the relevance of found articles
   * Assigns scores and establishes ranking order
   * Supports two-stage reranking

5. **Response Generation** (`5_generation.ex`)
   * Creates the final response based on highest-rated articles
   * Supports parallel generation (multiple response candidates)
   * Allows configuration of model, temperature, and reasoning options

6. **Response Reranking** (`6_response_rerank.ex`)
   * Verifies and selects the best response from candidates
   * Performs final quality control before returning the response

## Message Sending Workflow

1. **User** types a message in ChatView and clicks send
2. **Frontend validates** the message, authentication, chat ID
3. **HTTP POST** to `/api/chats/{chatId}/messages`
4. **Backend**:
   - Validates JWT token
   - Creates a Message record (role: "user")
   - Enqueues `RunPipelineJob` in the queue (Oban)
   - Returns `202 Accepted` immediately
5. **Async Job** — Worker executes the 6-stage pipeline:
   - Broadcasts progress via WebSocket
   - Creates Message record (role: "assistant")
   - Broadcasts new message via WebSocket
6. **Frontend WebSocket** — Listens for updates:
   - Updates AppContext state
   - ChatView re-renders with new messages

## Technology Stack

### **Frontend**
 * React - UI library
 * TypeScript - Language used in the frontend
 * Vite - Build tool and dev server
 * React Router - Client-side routing
 * TailwindCSS - Styling
 * Sonner - Notifications

### **Backend**
 * Phoenix - Web framework
 * Elixir - Runtime
 * Ecto - Database communication
 * Oban - Queueing and long-running task handling
 * Joken - JWT tokens
 * pgvector - Vector database

## Prerequisites

Before starting work, ensure you have installed:

- **Elixir** ~> 1.15 (with Erlang/OTP)
- **Node.js** (for the frontend)
- **Docker** and Docker Compose (for PostgreSQL database)
- **pdftotext** from `poppler-utils` package (required for importing PDF documents)

## Project Structure

```
pf-rag/
├── api/           # Backend (Elixir/Phoenix)
├── ui/            # Frontend (React/TypeScript/Vite)
├── db/            # Docker configuration for PostgreSQL with pgvector
└── docker-compose.yml  # Production configuration
```

## Initial Setup

Before the first run:

```bash
# 1. Copy the environment variables file
cp .env.example .env

# 2. Install backend dependencies
cd api && mix deps.get

# 3. Create and configure the database
mix ecto.setup

# 4. Install frontend dependencies
cd ../ui && npm install
```

## Development Commands

### Backend (`api/`)

```bash
cd api

# Development server (http://localhost:4000)
mix phx.server

# Database management
mix ecto.migrate     # Run migrations
mix ecto.reset       # Drop and recreate
```

### Frontend (`ui/`)

```bash
cd ui

# Development server (http://localhost:5173)
npm run dev
```

### Database

```bash
# Start only the database
docker compose -f db/docker-compose-dev.yml up -d

# Stop the database
docker compose -f db/docker-compose-dev.yml down
```

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth` | Login |
| POST | `/api/auth/register` | Registration |
| POST | `/api/auth/logout` | Logout |
| GET | `/api/auth/me` | Current user data |
| PATCH | `/api/auth/me/username` | Change username |
| PATCH | `/api/auth/me/password` | Change password |
| DELETE | `/api/auth/me` | Delete account |
| GET | `/api/auth/wstoken` | Token for WebSocket |

### API Keys
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/auth/keys` | List API keys |
| POST | `/api/auth/keys` | Add API key |
| POST | `/api/auth/keys/selected` | Select active key |
| DELETE | `/api/auth/keys/:key_id` | Delete API key |

### Chats
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/chats` | List user's chats |
| GET | `/api/chats/:chat_id` | Chat details |
| GET | `/api/chats/:chat_id/messages` | Messages in chat |
| POST | `/api/chats/new` | New chat with first message |
| POST | `/api/chats/:chat_id/messages` | Send message |
| POST | `/api/chats/:chat_id/rename` | Rename chat |
| POST | `/api/chats/:chat_id/retry` | Retry response generation |
| DELETE | `/api/chats/:chat_id` | Delete chat |
| DELETE | `/api/chats/:chat_id/messages/:message_id` | Delete message |

### Articles (Knowledge Base)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/articles` | List articles |
| GET | `/api/articles/:article_id` | Article details |

### Other
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |

## Environment Variables

The project uses an `.env` file for configuration. Copy `.env.example` to `.env` and set:

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENROUTER_API_KEY` | Yes* | API key for OpenRouter (used when importing documents) |
| `SECRET_KEY_BASE` | In production | Session encryption key (generate: `mix phx.gen.secret`) |

\* For end users, the API key is stored in the database, but the environment variable is required for importing documents into the knowledge base.

Alternatively, you can set the variable in the current session:
```bash
export OPENROUTER_API_KEY=your_key
```

## Tests

### Backend

```bash
cd api
mix test
```

The frontend currently does not have a configured test suite.

## Database Structure

The application uses PostgreSQL with the `pgvector` extension for storing vector embeddings.

### Tables

| Table | Description |
|-------|-------------|
| `users` | Users (id, username, password hash, selected_key_id, deleted_at) |
| `chats` | Chat sessions (id, name, author_id, deleted_at) |
| `messages` | Chat messages (id, content, role, metadata, chat_id, author_id, deleted_at) |
| `apikeys` | Encrypted LLM API keys (id, name, encrypted_key, owner_id) |
| `articles` | Knowledge base articles with embeddings (id, title, description, content, description_embedding, content_embedding, generation_cost, embedding_model) |
| `oban_jobs` | Background job queue (managed by Oban) |

**Note:** All user data uses "soft deletion" (`deleted_at` field) instead of physically deleting records.

## Running the Application

### Production Environment

```bash
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up -d
# Application available at localhost:80
```

### Development Environment

```bash
./start.sh
```

The script starts:
1. **PostgreSQL** in Docker at sql://localhost:5432
2. **Phoenix Backend** at http://localhost:4000
3. **Vite Frontend** at http://localhost:5173

## Adding Documents to the Knowledge Base

The application allows extending the knowledge base with new documents using the `rag.load` Mix task.

### Requirements

* Set environment variable `OPENROUTER_API_KEY`
* Installed `pdftotext` tool (from `poppler-utils` package) for PDF files

### Usage

```bash
cd api
mix rag.load path/to/document.pdf
```

The task handles PDF files as well as text files (`.txt`). The document will be split into fragments, which are then processed through the pipeline:

1. **Normalization and relevance scoring** - text is cleaned and evaluated for usefulness
2. **Title and description generation** - metadata is created for each fragment
3. **Embedding generation** - vectors are created for semantic search
4. **Database storage** - articles are saved in the `articles` table

### Configuration (optional)

In `api/config/config.exs` you can customize processing parameters.
