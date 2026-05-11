import * as React from "react"
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

import { Skeleton } from "./ui/skeleton"

interface Props {
    message: string;
}

export function UserMessage({ message }: Props): React.JSX.Element {
    return (
        <div>
            <div className="bg-secondary rounded-2xl px-4 py-2 max-w-2xl ml-auto w-fit">{message}</div>
            <div className="h-8" />
        </div>
    )
}

export function GeneratingMessage(): React.JSX.Element {
    return (
        <div>
            <Skeleton className="h-4 w-32" />
            <div className="h-8" />
        </div>
    )
}

export function AssistantMessage({ message }: Props): React.JSX.Element {
    return (
        <div>
            <ReactMarkdown remarkPlugins={[remarkGfm]}>
                {message}
            </ReactMarkdown>
            <div className="h-16" />
        </div>
    )
}
