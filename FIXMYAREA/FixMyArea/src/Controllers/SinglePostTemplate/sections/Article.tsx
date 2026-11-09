"use client";

import React from "react";
import { ArrowLeft, Calendar, Clock, Share2, Tag, User } from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Link } from "@/components/common/Link";
import { PostsProvider, usePosts } from "@/Services/wordpress/WordPressPostsProvider";
import { WP_Query } from "@/Services/wordpress/wp_query";

declare const wvcClient: {
  getCurrentWPQueryParams: () => Record<string, unknown>;
};

function RelatedPostsConsumer() {
  const { posts, loading } = usePosts();

  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[0, 1, 2].map((_, i) => (
          <div
            key={i}
            data-index={i}
            className="h-64 rounded-xl bg-muted/60 animate-pulse border border-border"
          />
        ))}
      </div>
    );
  }

  if (!posts || posts.length === 0) {
    return (
      <p className="text-muted-foreground text-sm">
        No related infrastructure updates found.
      </p>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {posts.slice(0, 3).map((item, i) => (
        <Card
          key={item.id}
          data-index={i}
          className="flex flex-col justify-between overflow-hidden border border-border bg-card transition-[transform,box-shadow] hover:-translate-y-1 hover:shadow-md"
        >
          {item.featuredImage && (
            <div className="aspect-video w-full overflow-hidden bg-muted">
              <img
                src={item.featuredImage}
                alt={item.title}
                loading="lazy"
                decoding="async"
                className="h-full w-full object-cover transition-transform duration-300 hover:scale-105"
              />
            </div>
          )}
          <CardHeader className="p-5">
            {item.categories && item.categories.length > 0 && (
              <span className="text-xs font-semibold text-primary uppercase tracking-wide">
                {item.categories[0].name}
              </span>
            )}
            <CardTitle className="text-lg font-semibold text-card-foreground line-clamp-2 mt-1">
              {item.title}
            </CardTitle>
          </CardHeader>
          <CardContent className="px-5 py-0 flex-1">
            {item.excerpt && (
              <p
                className="text-sm text-muted-foreground line-clamp-3"
                dangerouslySetInnerHTML={{ __html: item.excerpt }}
              />
            )}
          </CardContent>
          <CardFooter className="p-5 pt-4">
            <Link to={item.link || "#"} className="w-full">
              <Button variant="outline" size="sm" className="w-full">
                Read Article
              </Button>
            </Link>
          </CardFooter>
        </Card>
      ))}
    </div>
  );
}

function SinglePostConsumer() {
  const { posts, loading, error, refetch } = usePosts();

  if (loading) {
    return (
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="h-8 w-48 bg-muted rounded-md animate-pulse" />
        <div className="h-12 w-3/4 bg-muted rounded-md animate-pulse" />
        <div className="h-96 w-full bg-muted rounded-2xl animate-pulse" />
        <div className="space-y-3 pt-6">
          <div className="h-4 w-full bg-muted rounded animate-pulse" />
          <div className="h-4 w-5/6 bg-muted rounded animate-pulse" />
          <div className="h-4 w-4/6 bg-muted rounded animate-pulse" />
        </div>
      </div>
    );
  }

  if (error || !posts || posts.length === 0) {
    return (
      <div className="max-w-xl mx-auto text-center py-16 space-y-4">
        <h2 className="text-2xl font-semibold text-foreground">Post Not Found</h2>
        <p className="text-muted-foreground text-sm">
          We could not load the requested article or update. Please verify your connection or try again.
        </p>
        <div className="flex justify-center gap-3 pt-2">
          <Button variant="outline" onClick={() => refetch()}>
            Retry
          </Button>
          <Link to="/AdminPortalPage">
            <Button variant="default">Return to Portal</Button>
          </Link>
        </div>
      </div>
    );
  }

  const post = posts[0];
  const postDate = post.date
    ? new Date(post.date).toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
    : "Recent Update";

  const authorInitials = post.author?.name
    ? post.author.name
        .split(" ")
        .map((n) => n[0])
        .join("")
        .slice(0, 2)
        .toUpperCase()
    : "MU";

  const authorAvatarUrl = post.author?.avatar?.["96"] || post.author?.avatar?.["48"];

  const relatedQuery = new WP_Query({
    post_type: "post",
    per_page: 3,
  });

  return (
    <article className="max-w-4xl mx-auto">
      {/* Top back navigation and meta actions */}
      <div className="flex flex-wrap items-center justify-between gap-4 mb-8">
        <Link to="/AdminPortalPage">
          <Button variant="ghost" size="sm" className="text-muted-foreground hover:text-foreground">
            <ArrowLeft />
            Back to Portal
          </Button>
        </Link>
        {post.categories && post.categories.length > 0 && (
          <div className="flex items-center gap-2">
            {post.categories.map((cat, i) => (
              <span
                key={cat.id}
                data-index={i}
                className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-muted text-foreground border border-border"
              >
                <Tag className="size-3 text-primary" />
                {cat.name}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Primary Heading */}
      <header className="space-y-4 mb-8">
        <h1 className="text-3xl md:text-5xl font-bold tracking-tight text-foreground font-default">
          {post.title}
        </h1>

        <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground pt-2">
          <div className="flex items-center gap-2">
            <Avatar className="size-7 border border-border">
              {authorAvatarUrl && <AvatarImage src={authorAvatarUrl} alt={post.author?.name || "Author"} />}
              <AvatarFallback className="text-xs bg-muted text-foreground">{authorInitials}</AvatarFallback>
            </Avatar>
            <span className="font-medium text-foreground">{post.author?.name || "MUNICORE Staff"}</span>
          </div>
          <span className="text-border">•</span>
          <div className="flex items-center gap-1.5">
            <Calendar className="size-4" />
            <span>{postDate}</span>
          </div>
          <span className="text-border">•</span>
          <div className="flex items-center gap-1.5">
            <Clock className="size-4" />
            <span>4 min read</span>
          </div>
        </div>
      </header>

      {/* Featured Image */}
      {post.featuredImage && (
        <div className="mb-10 overflow-hidden rounded-2xl border border-border bg-muted shadow-sm">
          <img
            src={post.featuredImage}
            alt={post.title}
            className="w-full h-auto max-h-[500px] object-cover"
          />
        </div>
      )}

      {/* Post Content */}
      <div className="bg-card rounded-2xl p-6 md:p-10 border border-border shadow-xs">
        {post.content ? (
          <div
            className="prose prose-neutral max-w-none text-card-foreground leading-relaxed space-y-4 text-base md:text-lg"
            dangerouslySetInnerHTML={{ __html: post.content }}
          />
        ) : post.excerpt ? (
          <div
            className="text-card-foreground leading-relaxed text-base md:text-lg"
            dangerouslySetInnerHTML={{ __html: post.excerpt }}
          />
        ) : (
          <p className="text-muted-foreground text-base">
            Detailed content for this municipal infrastructure report is being processed.
          </p>
        )}

        {/* Tags list if available */}
        {post.tags && post.tags.length > 0 && (
          <div className="mt-10 pt-6 border-t border-border flex flex-wrap items-center gap-2">
            <span className="text-xs font-medium text-muted-foreground mr-1">Tagged:</span>
            {post.tags.map((tag, i) => (
              <span
                key={tag.id}
                data-index={i}
                className="text-xs px-2.5 py-1 rounded-md bg-muted text-muted-foreground"
              >
                #{tag.name}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Author Card */}
      <div className="my-10 rounded-2xl border border-border bg-card p-6 md:p-8 flex flex-col sm:flex-row items-center sm:items-start gap-5 shadow-xs">
        <Avatar className="size-16 border-2 border-border shrink-0">
          {authorAvatarUrl && <AvatarImage src={authorAvatarUrl} alt={post.author?.name || "Author"} />}
          <AvatarFallback className="text-lg bg-muted text-foreground">
            {authorInitials}
          </AvatarFallback>
        </Avatar>
        <div className="space-y-2 text-center sm:text-left flex-1">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-primary">Published by</p>
              <h2 className="text-xl font-semibold text-card-foreground">
                {post.author?.name || "Infrastructure Operations Team"}
              </h2>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                if (typeof navigator !== "undefined" && navigator.share) {
                  navigator.share({
                    title: post.title,
                    url: window.location.href,
                  }).catch(() => {});
                }
              }}
              className="gap-2 self-center sm:self-auto"
            >
              <Share2 className="size-3.5" />
              Share Report
            </Button>
          </div>
          <p className="text-sm text-muted-foreground leading-normal">
            Coordinating municipal reports, public safety warnings, and field response dispatches across Community City.
          </p>
        </div>
      </div>

      <Separator className="my-12" />

      {/* Related Posts Section */}
      <section className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold tracking-tight text-foreground font-default">
              Related Infrastructure Updates
            </h2>
            <p className="text-sm text-muted-foreground mt-1">
              Recent articles, logs, and maintenance dispatches from our crews.
            </p>
          </div>
          <Link to="/AdminPortalPage">
            <Button variant="outline" size="sm">
              View All
            </Button>
          </Link>
        </div>

        <PostsProvider wp_query={{ post_type: "post", per_page: 3, status: ["publish"] }}>
          <RelatedPostsConsumer />
        </PostsProvider>
      </section>
    </article>
  );
}

export default function Article() {
  const currentWPQueryParams = typeof wvcClient !== "undefined" && wvcClient.getCurrentWPQueryParams
    ? wvcClient.getCurrentWPQueryParams()
    : { post_type: "post", per_page: 1 };

  const wp_query = new WP_Query(currentWPQueryParams);

  return (
    <section
      id="single-post-template-section"
      data-nav="light"
      className="bg-background text-foreground py-12 md:py-20 px-4 sm:px-6 lg:px-8 border-b border-border min-h-screen"
    >
      <div className="max-w-7xl mx-auto">
        <PostsProvider wp_query={wp_query}>
          <SinglePostConsumer />
        </PostsProvider>
      </div>
    </section>
  );
}