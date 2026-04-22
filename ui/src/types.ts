export interface Message 
{
    id: string;
    role: "user" | "assistant";
    content: string;
    timestamp: string;
}

export interface Conversation
{
    id: string;
    label: string;
    messages: Message[];
}

export interface ConversationIdentifier
{
    id: string;
    label: string;
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
    label: string;
    documents: DatabaseDocument[];
}

export interface DatabaseIdentifier
{
    id: string;
    label: string;
}

export type View = "chat" | "database";
