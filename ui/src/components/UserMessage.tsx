import * as React from "react"

interface UserMessageProps {
    message: string;
}

export function UserMessage({ message }: UserMessageProps): React.JSX.Element {
    return (
        <div>
            <div className="bg-gray-100 rounded-2xl px-4 py-2 max-w-2xl ml-auto w-fit">{message}</div>
            <div className="h-8" />
        </div>
    )
}
