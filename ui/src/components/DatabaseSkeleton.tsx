import * as React from "react"
import {
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
} from "./ui/sidebar"

import { Skeleton } from "./ui/skeleton"

export function DatabaseSkeleton(): React.JSX.Element {
    const rows = Array.from({ length: 4 })
    return (
        <SidebarMenu>
            {rows.map((_, i) => (
                <SidebarMenuItem key={i}>
                    <SidebarMenuButton className="!cursor-default">
                        <div className="flex-1">
                            <Skeleton className="h-4 w-28" />
                        </div>
                        <div className="ml-auto mr-2">
                            <Skeleton className="h-4 w-6" />
                        </div>
                    </SidebarMenuButton>
                </SidebarMenuItem>
            ))}
        </SidebarMenu>
    )
}

export default DatabaseSkeleton
