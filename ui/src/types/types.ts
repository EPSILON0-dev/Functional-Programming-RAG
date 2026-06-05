export interface MessageMetadata
{
    error?: string;
}

export interface Message 
{
    id: string;
    role: "user" | "generating" | "error" | "assistant";
    content: string;
    timestamp: string;
    metadata?: MessageMetadata;
}

export interface NamedIdentifier
{
    id: string;
    name: string;
}

export interface Conversation
{
    id: string;
    name: string;
    timestamp: string;
}

export interface Article
{
    id: string;
    title: string;
    description: string;
    content: string;
    generation_cost: number;
    embedding_model: string;
    inserted_at: string;
}

export interface ArticlesListResponse
{
    articles: Article[];
    total: number;
    offset?: number;
    limit: number;
}

export type View = "landing" | "chat" | "database";
