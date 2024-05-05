import { Hono } from "hono";
import { basicAuth } from "hono/basic-auth";
import { AppBskyFeedPost, BskyAgent, RichText } from "@atproto/api";
import { logger } from "hono/logger";
import { Feed, Item } from "feed";
import { FeedViewPost } from "@atproto/api/dist/client/types/app/bsky/feed/defs";
import { extract } from "@extractus/article-extractor";
import { JSDOM } from "jsdom";
import DOMPurify from "dompurify";
import { parse } from "marked";
import { ProfileViewBasic } from "@atproto/api/dist/client/types/app/bsky/actor/defs";

type Variables = {
  agent: BskyAgent;
};

const app = new Hono<{ Variables: Variables }>();

app.use(logger());
app.use(
  "/",
  basicAuth({
    async verifyUser(username, password, c) {
      const agent = new BskyAgent({
        service: "https://bsky.social",
      });
      c.set("agent", agent);

      try {
        await agent.login({
          identifier: username,
          password,
        });
        return true;
      } catch (e) {
        return false;
      }
    },
  })
);

const blockedDomains = ["bsky.app"];

const findLink = (rt: RichText): string | undefined => {
  return Array.from(rt.segments())
    .reverse()
    .find((seg) => {
      if (seg.isLink()) {
        const url = new URL(seg.link!.uri);
        return !blockedDomains.includes(url.hostname);
      } else {
        return false;
      }
    })?.link?.uri;
};

const validPostToItem = async (
  agent: BskyAgent,
  post: AppBskyFeedPost.Record,
  author: ProfileViewBasic
): Promise<Item | null> => {
  const rt = new RichText({
    text: post.text,
    facets: post.facets,
  });
  const link = findLink(rt);
  if (!link) {
    return null;
  }

  let markdown = `
  [${author.displayName}](https://bsky.app/profile/${author.handle}) posted:
  `;
  for (const segment of rt.segments()) {
    if (segment.isLink()) {
      markdown += `[${segment.text}](${segment.link?.uri})`;
    } else if (segment.isMention()) {
      const author = await agent.getProfile({
        actor: segment.mention!.did,
      });
      markdown += `[${segment.text}](https://bsky.app/profile/${author.data.handle})`;
    } else {
      markdown += segment.text;
    }
  }
  const window = new JSDOM("").window;
  const purify = DOMPurify(window);
  let content = await parse(markdown);
  content = purify.sanitize(content);

  console.log(JSON.stringify(post));

  let title = post.embed?.title || `${post.text.slice(0, 50)}...`;

  try {
    const article = await extract(link);
    if (article && article.content) {
      content = `
      ${content}
      ---
      ${article.content}
      `;
    }
    if (article && article.title) {
      title = article.title;
    }
  } catch (e) {
    console.error(e);
  }

  return {
    title: title as string,
    content: content,
    link: link,
    date: new Date(post.createdAt),
  };
};

const postToItem = async (
  agent: BskyAgent,
  post: FeedViewPost
): Promise<Item | null> => {
  if (AppBskyFeedPost.isRecord(post.post.record)) {
    const res = AppBskyFeedPost.validateRecord(post.post.record);
    if (res.success) {
      return validPostToItem(agent, post.post.record, post.post.author);
    } else {
      console.error(res.error);
      return null;
    }
  } else {
    console.error("post is not a record");
    return null;
  }
};

app.get("/", async (c) => {
  const agent = c.get("agent") as BskyAgent;
  const timeline = await agent.getTimeline();
  const feed = new Feed({
    title: "bluesky links",
    description: "RSS feed of all links found in posts of users you follow",
    id: "https://bsky.app/",
    link: "https://bsky.app/",
    language: "en-us",
    copyright: "",
  });
  const feedItems = await Promise.all(
    timeline.data.feed.map((post) => {
      return postToItem(agent, post);
    })
  );
  feedItems.forEach((item) => {
    if (item) {
      feed.addItem(item);
    }
  });

  c.res.headers.set("Content-Type", "application/rss+xml");
  return c.text(feed.rss2());
});

export default app;
