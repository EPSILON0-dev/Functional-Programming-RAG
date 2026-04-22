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

import type { NamedIdentifier } from "@/types";
import DatabaseSkeleton from "./DatabaseSkeleton";
import { Skeleton } from "./ui/skeleton";

interface Props {
    open: boolean;
    databases: NamedIdentifier[] | null;
    onDatabaseSelect: (database: NamedIdentifier) => void;
}

export function NavDatabases(props: Props): React.JSX.Element {
    return (
        <>
            {props.open &&
                <SidebarGroup>
                    <SidebarGroupLabel>
                        {props.databases ? "Databases" : <Skeleton className="h-4 w-24" />}
                    </SidebarGroupLabel>
                    <SidebarMenu>
                        {props.databases ? props.databases?.map((db) => (
                            <SidebarMenuItem className="group/item" key={db.id}>
                                <SidebarMenuButton
                                    className="active:bg-gray-200 transition-all duration-50"
                                    onClick={() => props.onDatabaseSelect(db)}
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
                        )) : (
                            <div className="pointer-events-none">
                                <SidebarMenuItem>
                                    <DatabaseSkeleton />
                                </SidebarMenuItem>
                            </div>
                        )}
                    </SidebarMenu>
                </SidebarGroup>
            }
        </>
    )
}
