export interface Message 
{
    id: string;
    role: "user" | "assistant";
    content: string;
    timestamp: string;
}

export interface Chat
{
    id: string;
    name: string;
}

export interface NamedIdentifier
{
    id: string;
    name: string;
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
