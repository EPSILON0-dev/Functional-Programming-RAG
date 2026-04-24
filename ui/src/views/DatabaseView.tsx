import React from "react";
import { Card, CardDescription, CardTitle } from "@/components/ui/card"
import { IconCylinder } from "@tabler/icons-react"
import type { Database } from '@/types';
import { useQuery } from '@tanstack/react-query';
import { useParams } from 'react-router-dom';
import { SearchInput } from "@/components/SearchInput";

export function DatabaseView(): React.JSX.Element {
    const { databaseId } = useParams<{ databaseId: string }>();
    const [filter, setFilter] = React.useState("")

    const { data: database, isLoading, isError } = useQuery<Database>({
        queryKey: ["database", databaseId],
        queryFn: async () => {
            const response = await fetch(`/api/databases/${databaseId}`);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            return response.json();
        },
    });

    const onMessageSent = async (message: string) => {
        setFilter(message)
    }

    const isMatchMock = (item: { title: string; abstract: string }) => {
        return item.title.toLowerCase().includes(filter.toLowerCase()) ||
            item.abstract.toLowerCase().includes(filter.toLowerCase());
    }

    return (
        <div className="flex flex-col h-screen min-w-0 flex-1">
            <header className="shrink-0">
                <div className="shrink-0 px-4 py-2 border-b">
                    <div className="flex justify-center items-center">
                        <div className="flex-row flex gap-2 items-center">
                            <IconCylinder />
                            <h1 className="text-center">{database?.label}</h1>
                        </div>
                    </div>
                </div>
                <div className="px-4 py-4 max-w-4xl mx-auto">
                    <SearchInput placeholderText={`Search database "${database?.label}" . . . `} onMessageSent={onMessageSent} />
                </div>
            </header>
            <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                <main className="p-4">
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        {database?.documents.filter((item) => isMatchMock(item)).map((item, index) => (
                            <Card key={index} className="m-0 p-4">
                                <CardTitle>{item.title}</CardTitle>
                                <CardDescription>{item.abstract}</CardDescription>
                            </Card>
                        ))}
                    </div>
                </main>
            </div>
        </div >
    )
}
