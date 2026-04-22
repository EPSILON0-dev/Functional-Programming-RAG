from fastapi import FastAPI
from .stubs.databases import DATABASES
from .stubs.conversations import CONVERSATIONS

app = FastAPI()


@app.get("/api/databases/")
def get_databases(offset: int = 0, limit: int = 10):
    sliced = DATABASES[offset:offset + limit]
    return [{"label": db.label, "id": db.id} for db in sliced]


@app.get("/api/databases/{database_id}/documents")
def get_documents(database_id: str, offset: int = 0, limit: int = 10):
    db = next((d for d in DATABASES if d.id == database_id), None)
    if db is None:
        return []
    docs = db.documents[::-1][offset:offset + limit]
    return {"label": db.label, "id": db.id, "documents": [{"id": doc.id, "title": doc.title, "abstract": doc.abstract, "content": doc.content} for doc in docs]}


@app.get("/api/conversations")
def get_conversations(offset: int = 0, limit: int = 10):
    sliced = CONVERSATIONS[offset:offset + limit]
    return [{"id": conv.id, "label": conv.label} for conv in sliced]


@app.get("/api/conversations/{conversation_id}/messages")
def get_conversation_messages(conversation_id: str, offset: int = 0, limit: int = 10):
    conv = next((c for c in CONVERSATIONS if c.id == conversation_id), None)
    if conv is None:
        return []
    msgs = conv.messages[::-1][offset:offset + limit]
    return { "id": conv.id, "label": conv.label, "messages": [{"id": msg.id, "role": msg.role, "content": msg.content, "timestamp": msg.timestamp} for msg in msgs] }
