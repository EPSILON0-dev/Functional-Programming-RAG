import * as React from "react"
import {
    SidebarGroup,
    SidebarGroupLabel,
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
} from "./ui/sidebar"

import {
    IconCylinder,
    IconDots,
} from "@tabler/icons-react"

import type { DatabaseIdentifier } from "@/types";

interface NavDatabasesInterface {
    open: boolean;
    databases: DatabaseIdentifier[];
    onDatabaseSelect: (databaseId: string) => void;
}

export function NavDatabases(props: NavDatabasesInterface): React.JSX.Element {
    return (
        <SidebarGroup>
            <SidebarGroupLabel>Databases</SidebarGroupLabel>
            <SidebarMenu>
                {props.databases.map((db) => (
                    <SidebarMenuItem className="group/item" key={db.id}>
                        <SidebarMenuButton
                            className="active:bg-gray-200 transition-all duration-50"
                            onClick={() => props.onDatabaseSelect(db.id)}
                        >
                            <IconCylinder className={`mr-2 ${props.open ? "opacity-100" : "opacity-0"} transition-all duration-100`} />
                            <span className="whitespace-nowrap truncate">{db.label}</span>
                            <div
                                className="ml-auto mr-2 max-h-fit"
                                onClick={(e) => { e.stopPropagation(); console.log(`Database ${db.label} options clicked`); }}
                            >
                                <IconDots className="opacity-40 max-w-0 group-hover/item:max-w-full hover:opacity-100 transition-all duration-100" />
                            </div>
                        </SidebarMenuButton>
                    </SidebarMenuItem>
                ))}
            </SidebarMenu>
        </SidebarGroup>
    )
}
