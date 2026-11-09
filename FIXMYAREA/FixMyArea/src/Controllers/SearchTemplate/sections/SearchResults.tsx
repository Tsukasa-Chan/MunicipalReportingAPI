"use client";

import React from "react";
import { TriangleAlert as AlertCircle, ArrowLeft, ArrowRight, Calendar, FileQuestionMark as FileQuestion, Search as SearchIcon } from 'lucide-react';
import { Link } from "@/components/common/Link";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { PostsProvider, usePosts } from "@/Services/wordpress/WordPressPostsProvider";
import { WP_Query } from "@/Services/wordpress/wp_query";

declare const wvcClient: {
  getCurrentWPQueryParams: () => Record<string, any>;
};

function SearchConsumer({ searchTerm }: { searchTerm: string }) {
  const {
    posts,
    loading,
    error,
    refetch,
    hasNext,
    hasPrev,
    nextPage,
    prevPage,
    currentPage,
    totalPages,
    total,
  } = usePosts();

  return (
    <div className="mx-auto max-w-6xl px-4 py-12 md:py-16">
      {/* Header section with active search term */}
      <div className="mb-8 border-b border-border pb-6 md:mb-10">
        <div className="inline-flex items-center gap-2 rounded-full bg-accent/20 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-accent-foreground">
          <SearchIcon className="size-3.5" />
          <span>Search Results</span>
        </div>
        <h1 className="mt-3 font-default text-3xl font-bold tracking-tight text-foreground sm:text-4xl md:text-5xl">
          {searchTerm ? (
            <>
              Results for <span className="text-primary">"{searchTerm}"</span>
            </>
          ) : (
            "Explore Content & Reports"
          )}
        </h1>
        <p className="mt-2 text-sm text-muted-foreground sm:text-base">
          {loading
            ? "Looking through articles, announcements, and municipal records..."
            : `Showing ${posts.length} ${posts.length === 1 ? "result" : "results"}${
                total > 0 ? ` out of ${total}` : ""
              }`}
        </p>
      </div>

      {/* Loading state */}
      {loading && (
        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Card
              key={i}
              data-index={i}
              className="overflow-hidden border border-border bg-card shadow-xs animate-pulse"
            >
              <div className="h-48 w-full bg-muted/60" />
              <CardHeader className="space-y-2">
                <div className="h-4 w-1/3 rounded-sm bg-muted/70" />
                <div className="h-6 w-5/6 rounded-sm bg-muted/70" />
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="h-4 w-full rounded-sm bg-muted/60" />
                <div className="h-4 w-4/5 rounded-sm bg-muted/60" />
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Error state */}
      {!loading && error && (
        <Alert variant="destructive" className="my-6 border border-destructive/30">
          <AlertCircle className="size-4" />
          <AlertTitle>Search Failed</AlertTitle>
          <AlertDescription className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <span>Unable to load search results at this time. Please try again.</span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => refetch()}
              className="w-fit"
            >
              Retry
            </Button>
          </AlertDescription>
        </Alert>
      )}

      {/* Empty state */}
      {!loading && !error && posts.length === 0 && (
        <div className="my-8 rounded-xl border border-dashed border-border bg-card p-8 text-center sm:p-12">
          <div className="mx-auto mb-4 flex size-12 items-center justify-center rounded-full bg-muted text-muted-foreground">
            <FileQuestion className="size-6" />
          </div>
          <h2 className="font-default text-xl font-semibold text-foreground">
            No results found
          </h2>
          <p className="mx-auto mt-2 max-w-md text-sm text-muted-foreground">
            {searchTerm
              ? `We could not find any matching items for "${searchTerm}". Try checking your spelling or using more general keywords.`
              : "No posts or documents match your query. Try a different search keyword."}
          </p>
          <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
            <Button variant="default" asChild>
              <Link to="/">Back to Homepage</Link>
            </Button>
            <Button variant="outline" asChild>
              <Link to="/AdminPortalPage">Admin Portal</Link>
            </Button>
          </div>
        </div>
      )}

      {/* Results grid */}
      {!loading && !error && posts.length > 0 && (
        <>
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {posts.map((post, i) => (
              <Card
                key={post.id}
                data-index={i}
                className="group flex flex-col justify-between overflow-hidden border border-border bg-card transition-shadow hover:shadow-md"
              >
                <div>
                  {post.featuredImage && (
                    <div className="relative h-48 w-full overflow-hidden bg-muted">
                      <img
                        src={post.featuredImage}
                        alt={post.title || "Post thumbnail"}
                        loading="lazy"
                        className="size-full object-cover transition-transform duration-300 group-hover:scale-105"
                      />
                    </div>
                  )}

                  <CardHeader className="space-y-2">
                    {post.date && (
                      <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                        <Calendar className="size-3.5" />
                        <span>{new Date(post.date).toLocaleDateString()}</span>
                      </div>
                    )}
                    <CardTitle className="font-default text-lg font-bold text-foreground group-hover:text-primary">
                      {post.link ? (
                        <Link to={post.link} className="hover:underline">
                          {post.title || "Untitled"}
                        </Link>
                      ) : (
                        post.title || "Untitled"
                      )}
                    </CardTitle>
                  </CardHeader>

                  {post.excerpt && (
                    <CardContent>
                      <div
                        className="line-clamp-3 text-sm leading-relaxed text-muted-foreground"
                        dangerouslySetInnerHTML={{ __html: post.excerpt }}
                      />
                    </CardContent>
                  )}
                </div>

                <CardFooter className="pt-2">
                  {post.link ? (
                    <Button variant="outline" size="sm" asChild className="w-full">
                      <Link to={post.link}>Read Article</Link>
                    </Button>
                  ) : (
                    <span className="text-xs text-muted-foreground">Reference post</span>
                  )}
                </CardFooter>
              </Card>
            ))}
          </div>

          {/* Pagination controls */}
          {(totalPages > 1 || hasNext || hasPrev) && (
            <div className="mt-12 flex flex-col items-center justify-between gap-4 border-t border-border pt-6 sm:flex-row">
              <p className="text-sm text-muted-foreground">
                Page {currentPage || 1} of {totalPages || 1}
              </p>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => prevPage()}
                  disabled={!hasPrev}
                >
                  <ArrowLeft className="size-4" />
                  <span>Previous</span>
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => nextPage()}
                  disabled={!hasNext}
                >
                  <span>Next</span>
                  <ArrowRight className="size-4" />
                </Button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default function SearchResults() {
  const current_wp_query_params =
    typeof wvcClient !== "undefined" && wvcClient.getCurrentWPQueryParams
      ? wvcClient.getCurrentWPQueryParams()
      : {};

  const wp_query = new WP_Query(current_wp_query_params);
  const rawSearchTerm = current_wp_query_params?.s;
  const searchTerm = typeof rawSearchTerm === "string" ? rawSearchTerm : "";

  return (
    <section
      id="search-template-section"
      data-nav="light"
      className="relative min-h-[70vh] bg-background text-foreground"
    >
      <PostsProvider wp_query={wp_query}>
        <SearchConsumer searchTerm={searchTerm} />
      </PostsProvider>
    </section>
  );
}