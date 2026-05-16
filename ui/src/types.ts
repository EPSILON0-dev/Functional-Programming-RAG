export interface Message 
{
    id: string;
    role: "user" | "generating" | "error" | "assistant";
    content: string;
    timestamp: string;
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

export interface DatabaseDocument
{
    id: string;
    title: string;
    abstract: string;
    content: string;
}

export interface Database
{
    id: string;
    name: string;
    documents: DatabaseDocument[];
}

export type View = "landing" | "chat" | "database";
