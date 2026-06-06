import React from "react";
import { Card, CardDescription, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { IconBooks, IconArrowLeft, IconChevronLeft, IconChevronRight, IconX } from "@tabler/icons-react"
import { ErrorBoundary } from "@/components/ErrorBoundary"
import type { Article, ArticlesListResponse } from '@/types/types';
import { SearchInput } from "@/components/SearchInput";
import { useQuery, keepPreviousData, useQueryClient } from "@tanstack/react-query";
import { useParams, useNavigate } from "react-router-dom";

const PAGE_SIZE = 20;
const WINDOW = 2; // pages shown on each side of current page

export function DatabaseView(): React.JSX.Element {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const { articleId } = useParams<{ articleId?: string }>();
  const [filter, setFilter] = React.useState("")
  const [currentPage, setCurrentPage] = React.useState(1)
  const selectedArticleId = articleId || null;

  const offset = (currentPage - 1) * PAGE_SIZE;
  const isSearching = filter.trim() !== "";

  const { data: browseData, isLoading: browseLoading, isError: browseError } = useQuery<ArticlesListResponse>({
    queryKey: ["articles", "browse", offset],
    queryFn: async () => {
      const res = await fetch(`/api/articles?offset=${offset}&limit=${PAGE_SIZE}`);
      if (!res.ok) throw new Error("Failed to fetch articles");
      return res.json();
    },
    placeholderData: keepPreviousData,
    enabled: !isSearching,
  });

  const { data: searchData, isLoading: searchLoading, isError: searchError } = useQuery<ArticlesListResponse>({
    queryKey: ["articles", "search", filter.trim()],
    queryFn: async () => {
      const res = await fetch(`/api/articles?q=${encodeURIComponent(filter.trim())}&limit=50`);
      if (!res.ok) throw new Error("Failed to search articles");
      return res.json();
    },
    enabled: isSearching,
  });

  const { data: articleDetail, isLoading: detailLoading } = useQuery<Article>({
    queryKey: ["article", selectedArticleId],
    queryFn: async () => {
      const res = await fetch(`/api/articles/${selectedArticleId}`);
      if (!res.ok) throw new Error("Failed to fetch article");
      return res.json();
    },
    enabled: selectedArticleId != null,
    initialData: () => {
      const cached = queryClient.getQueriesData<ArticlesListResponse>({ queryKey: ["articles"] });
      for (const [, page] of cached) {
        const found = page?.articles.find((a) => a.id === selectedArticleId);
        if (found) return found;
      }
      return undefined;
    },
  });

  const handleArticleClick = (id: string) => {
    navigate(`/explore/${id}`);
  };

  const handleBackClick = () => {
    navigate("/explore");
  };

  const onMessageSent = async (message: string) => {
    setFilter(message)
    setCurrentPage(1)
  }

  const clearSearch = () => {
    setFilter("")
    setCurrentPage(1)
  }

  const activeData = isSearching ? searchData : browseData;
  const isLoading = isSearching ? searchLoading : browseLoading;
  const isError = isSearching ? searchError : browseError;
  const articles = activeData?.articles ?? [];
  const total = activeData?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  if (selectedArticleId != null) {
    return (
      <div className="flex flex-col h-screen min-w-0 flex-1">
        <header className="shrink-0">
          <div className="shrink-0 px-4 py-2 border-b">
            <div className="flex items-center gap-2">
              <Button variant="ghost" size="sm" onClick={handleBackClick}>
                <IconArrowLeft className="mr-1" />
                Back
              </Button>
              <div className="flex items-center gap-2 mx-auto">
                <IconBooks />
                <h1 className="text-center font-semibold">Explore Articles</h1>
              </div>
            </div>
          </div>
        </header>
        <div className="max-w-3xl min-w-0 mx-auto w-full px-4 py-8 overflow-y-auto">
          <ErrorBoundary>
            {detailLoading ? (
              <p className="text-muted-foreground text-center py-12">Loading article…</p>
            ) : articleDetail ? (
              <>
                <h2 className="text-2xl font-bold mb-2">{articleDetail.title}</h2>
                <p className="text-muted-foreground mb-6 italic">{articleDetail.description}</p>
                <hr className="mb-6" />
                <p className="leading-relaxed whitespace-pre-wrap">{articleDetail.content}</p>
              </>
            ) : (
              <p className="text-muted-foreground text-center py-12">Article not found.</p>
            )}
          </ErrorBoundary>
        </div>
      </div>
    )
  }

  return (
    <div className="flex flex-col h-screen min-w-0 flex-1">
      <header className="shrink-0">
        <div className="shrink-0 px-4 py-2 border-b">
          <div className="flex justify-center items-center">
            <div className="flex-row flex gap-2 items-center">
              <IconBooks />
              <h1 className="text-center font-semibold">Explore Articles</h1>
            </div>
          </div>
        </div>
        <div className="px-4 py-4 max-w-4xl mx-auto w-full">
          <SearchInput placeholderText="Search articles . . ." onMessageSent={onMessageSent} />
          {isSearching && (
            <div className="mt-2 flex items-center gap-2">
              <span className="text-sm text-muted-foreground">Results for: <span className="font-medium text-foreground">&ldquo;{filter}&rdquo;</span></span>
              <button
                onClick={clearSearch}
                className="ml-1 flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors"
              >
                <IconX size={12} /> Clear
              </button>
            </div>
          )}
        </div>
      </header>
      <div className="max-w-4xl min-w-0 mx-auto w-full px-4 flex flex-col flex-1 overflow-hidden">
        <main className="p-4 flex-1 overflow-y-auto">
          <ErrorBoundary>
            {isLoading ? (
              <p className="text-muted-foreground text-center py-12">Loading articles…</p>
            ) : isError ? (
              <p className="text-destructive text-center py-12">Failed to load articles.</p>
            ) : articles.length === 0 ? (
              <p className="text-muted-foreground text-center py-12">{isSearching ? "No articles match your search." : "No articles found."}</p>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {articles.map((item) => (
                  <Card
                    key={item.id}
                    className="m-0 p-4 cursor-pointer hover:shadow-md transition-shadow flex flex-col gap-2"
                    onClick={() => handleArticleClick(item.id)}
                  >
                    <CardTitle className="text-base leading-snug">{item.title}</CardTitle>
                    <CardDescription className="line-clamp-3">{item.description}</CardDescription>
                  </Card>
                ))}
              </div>
            )}
          </ErrorBoundary>
        </main>
        <div className="shrink-0 py-4 flex items-center justify-center gap-1 flex-wrap">
          {!isSearching && (<>
            <Button
              variant="outline"
              size="icon-sm"
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1 || isLoading}
            >
              <IconChevronLeft />
            </Button>
            {(() => {
              const pages: React.ReactNode[] = [];
              const start = Math.max(1, currentPage - WINDOW);
              const end = Math.min(totalPages, currentPage + WINDOW);
              if (start > 1) {
                pages.push(
                  <Button key={1} variant="outline" size="icon-sm" onClick={() => setCurrentPage(1)}>1</Button>
                );
                if (start > 2) pages.push(<span key="ellipsis-start" className="px-1 text-muted-foreground select-none">…</span>);
              }
              for (let p = start; p <= end; p++) {
                pages.push(
                  <Button
                    key={p}
                    variant={p === currentPage ? "default" : "outline"}
                    size="icon-sm"
                    onClick={() => setCurrentPage(p)}
                  >
                    {p}
                  </Button>
                );
              }
              if (end < totalPages) {
                if (end < totalPages - 1) pages.push(<span key="ellipsis-end" className="px-1 text-muted-foreground select-none">…</span>);
                pages.push(
                  <Button key={totalPages} variant="outline" size="icon-sm" onClick={() => setCurrentPage(totalPages)}>{totalPages}</Button>
                );
              }
              return pages;
            })()}
            <Button
              variant="outline"
              size="icon-sm"
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages || isLoading}
            >
              <IconChevronRight />
            </Button>
          </>)}
        </div>
      </div>
    </div>
  )
}
