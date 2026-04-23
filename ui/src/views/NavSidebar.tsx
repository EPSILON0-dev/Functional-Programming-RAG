import {
    Sidebar,
    SidebarContent,
    SidebarFooter,
    useSidebar,
} from "@/components/ui/sidebar"

import { NavDatabases } from "@/components/NavDatabases"
import { NavHeader } from "@/components/NavHeader"
import { NavChats } from "@/components/NavChats"

export function NavSidebar(): React.JSX.Element {
    const { open } = useSidebar()
    return (
        <Sidebar collapsible="icon">
            <NavHeader />
            <SidebarContent className={`${open ? "" : "pointer-events-none"}`}>
                <NavDatabases />
                <NavChats />
            </SidebarContent>
            <SidebarFooter>
            </SidebarFooter>
        </Sidebar >
    )
}
