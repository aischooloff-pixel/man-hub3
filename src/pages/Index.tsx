import { useState } from 'react';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { ArticleCarousel } from '@/components/articles/ArticleCarousel';
import { PodcastCarousel } from '@/components/podcasts/PodcastCarousel';
import { PremiumBanner } from '@/components/premium/PremiumBanner';
import { CategoryList } from '@/components/categories/CategoryList';
import { TelegramCTA } from '@/components/cta/TelegramCTA';
import { ArticleCard } from '@/components/articles/ArticleCard';
import {
  mockArticles,
  mockPodcasts,
  mockCategories,
  currentUser,
} from '@/data/mockData';
import { Category } from '@/types';

export default function Index() {
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);

  // Sort by likes descending for "Популярное"
  const featuredArticles = [...mockArticles]
    .sort((a, b) => b.likes_count - a.likes_count)
    .slice(0, 4);
  const latestArticles = mockArticles.slice(2);

  const filteredArticles = selectedCategory
    ? latestArticles.filter((a) => a.category_id === selectedCategory.id)
    : latestArticles;

  return (
    <div className="min-h-screen bg-background pb-24 pt-16">
      <Header />

      <main className="py-6">
        {/* Welcome Section */}
        <section className="mb-8 px-4">
          <h1 className="mb-2 font-heading text-2xl font-bold">
            Привет, {currentUser.first_name}
          </h1>
          <p className="text-muted-foreground">
            Что нового в сообществе сегодня
          </p>
        </section>

        {/* Categories */}
        <CategoryList
          categories={mockCategories}
          selectedId={selectedCategory?.id}
          onSelect={setSelectedCategory}
          className="mb-8"
        />

        {/* Featured Articles */}
        <ArticleCarousel
          title="Популярное"
          articles={featuredArticles}
          className="mb-8"
        />

        {/* Podcasts */}
        <PodcastCarousel
          title="Подкасты"
          podcasts={mockPodcasts}
          className="mb-8"
        />

        {/* Premium Banner */}
        {!currentUser.is_premium && <PremiumBanner className="mb-8" />}

        {/* Latest Articles */}
        <section className="mb-8 px-4">
          <h2 className="mb-4 font-heading text-xl font-semibold">
            Последние статьи
          </h2>
          <div className="space-y-4">
            {filteredArticles.map((article, index) => (
              <ArticleCard
                key={article.id}
                article={article}
                className="animate-slide-up"
                style={{ animationDelay: `${index * 100}ms` } as React.CSSProperties}
              />
            ))}
          </div>
        </section>

        {/* Telegram CTA */}
        <TelegramCTA className="mb-8" />
      </main>

      <BottomNav />
    </div>
  );
}
