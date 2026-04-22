import {
    Sidebar,
    SidebarContent,
    SidebarFooter,
    useSidebar,
} from "@/components/ui/sidebar"

import { NavDatabases } from "@/components/NavDatabases"
import { NavHeader } from "@/components/NavHeader"
import { NavConversations } from "@/components/NavConversations"
import type { NamedIdentifier } from "@/types"

interface Props {
    onNewConversation: () => void;
    onSelectConversation: (conversation: NamedIdentifier) => void;
    onDeleteConversation: (conversation: NamedIdentifier) => void;
    conversations: NamedIdentifier[] | null;
    onNewDatabase: () => void;
    onSelectDatabase: (database: NamedIdentifier) => void;
    onDeleteDatabase: (database: NamedIdentifier) => void;
    databases: NamedIdentifier[] | null;
};

export function NavSidebar(props: Props): React.JSX.Element {
    const { open } = useSidebar()
    return (
        <Sidebar collapsible="icon">
            <NavHeader
                open={open}
                onNewConversation={props.onNewConversation}
                onNewDatabase={props.onNewDatabase}
            />
            <SidebarContent className={`${open ? "" : "pointer-events-none"}`}>
                <NavDatabases
                    open={open}
                    databases={props.databases}
                    onDatabaseSelect={props.onSelectDatabase}
                />
                <NavConversations
                    open={open}
                    conversations={props.conversations}
                    onConversationSelect={props.onSelectConversation}
                />
            </SidebarContent>
            <SidebarFooter>
            </SidebarFooter>
        </Sidebar >
    )
}
