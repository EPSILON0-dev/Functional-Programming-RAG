from fastapi import FastAPI
from .stubs.databases import DATABASES
from .stubs.conversations import CONVERSATIONS

app = FastAPI()


@app.get("/api/databases/")
def get_databases(offset: int = 0, limit: int = 10):
    sliced = DATABASES[offset:offset + limit]
    return [{"label": db.label, "id": db.id} for db in sliced]


@app.get("/api/databases/{database_id}")
def get_documents(database_id: str, offset: int = 0, limit: int = 10):
    db = next((d for d in DATABASES if d.id == database_id), None)
    if db is None:
        return []
    docs = db.documents[::-1][offset:offset + limit]
    return {"label": db.label, "id": db.id, "documents": [{"id": doc.id, "title": doc.title, "abstract": doc.abstract} for doc in docs]}


@app.get("/api/databases/{database_id}/documents/{document_id}")
def get_document(database_id: str, document_id: str):
    db = next((d for d in DATABASES if d.id == database_id), None)
    if db is None:
        return []
    doc = next((d for d in db.documents if d.id == document_id), None)
    if doc is None:
        return []
    return {"id": doc.id, "title": doc.title, "abstract": doc.abstract, "content": doc.content}


@app.get("/api/chats")
def get_chats(offset: int = 0, limit: int = 10):
    sliced = CONVERSATIONS[offset:offset + limit]
    return [{"id": conv.id, "label": conv.label} for conv in sliced]


@app.get("/api/chats/{chat_id}")
def get_chat_messages(chat_id: str, offset: int = 0, limit: int = 10):
    conv = next((c for c in CONVERSATIONS if c.id == chat_id), None)
    if conv is None:
        return []
    msgs = conv.messages[::-1][offset:offset + limit]
    return { "id": conv.id, "label": conv.label, "messages": [{"id": msg.id, "role": msg.role, "content": msg.content, "timestamp": msg.timestamp} for msg in msgs] }
