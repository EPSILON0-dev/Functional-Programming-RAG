import { ChatInput } from "../components/ChatInput"
import { DatabaseDropdown } from "../components/DatabaseDropdown"
import type { NamedIdentifier } from "@/types"

interface Props {
    databases: NamedIdentifier[] | null;
    selectedDatabase: NamedIdentifier | null;
    onSelectDatabase: (database: NamedIdentifier) => void;
};

export function LandingView(props: Props): React.JSX.Element {
    return (
        <div className="flex flex-col h-screen min-w-0 flex-1">
            <main className="m-auto max-w-4xl w-full">
                <div className="mx-8">
                    <h1 className="text-3xl text-center mb-12">Select the database and ask a question</h1>
                    <ChatInput />
                    <div className="ml-2 mt-2">
                        <DatabaseDropdown
                            databases={props.databases}
                            selectedDatabase={props.selectedDatabase}
                            onSelectDatabase={props.onSelectDatabase}
                        />
                    </div>
                </div>
            </main>
        </div>
    )
}
