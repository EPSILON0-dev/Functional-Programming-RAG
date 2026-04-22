import { useState, useEffect } from 'react';
import type { Database } from '@/types';
import { Card, CardDescription, CardTitle } from "@/components/ui/card"

import { IconCylinder } from "@tabler/icons-react"

export function DatabaseView(props: { selectedDatabaseId: string | null }): React.JSX.Element {
    const [database, setDatabase] = useState<Database>();

    const fetchDatabases = () => {
        if (!props.selectedDatabaseId) return;
        fetch(`http://localhost:8000/api/databases/${props.selectedDatabaseId}/documents`)
            .then(res => res.json())
            .then(data => setDatabase(data))
            .catch(err => console.error("Fetch failed:", err));
    };

    useEffect(() => {
        fetchDatabases();
        console.log(`Fetching database ID: ${props.selectedDatabaseId}`);
    }, [props.selectedDatabaseId]);

    return (
        <div className="flex flex-col h-screen min-w-0 flex-1">
            <header className="shrink-0 px-4 py-2 border-b">
                <div className="flex justify-center items-center">
                    <div className="flex-row flex gap-2 items-center">
                        <IconCylinder />
                        <h1 className="text-center">{database?.label}</h1>
                    </div>
                </div>
            </header>
            <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                <main className="p-4">
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        {database?.documents.map((item, index) => (
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
