import { useState } from 'react';
import { Header } from '@/components/layout/Header';
import { BottomNav } from '@/components/layout/BottomNav';
import { CategoryList } from '@/components/categories/CategoryList';
import { ArticleListCard } from '@/components/articles/ArticleListCard';
import { CreateArticleModal } from '@/components/articles/CreateArticleModal';
import { UserArticlesModal } from '@/components/profile/UserArticlesModal';
import { Button } from '@/components/ui/button';
import { Plus, ChevronRight, FileText } from 'lucide-react';
import { mockArticles, mockCategories, currentUser } from '@/data/mockData';
import { Category, Article } from '@/types';

export default function Hub() {
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [showAllArticles, setShowAllArticles] = useState(false);
  const [isMyArticlesOpen, setIsMyArticlesOpen] = useState(false);

  const filteredArticles = selectedCategory
    ? mockArticles.filter((a) => a.category_id === selectedCategory.id)
    : mockArticles;

  // Show only first 5 articles unless "show all" is clicked
  const displayedArticles = showAllArticles ? filteredArticles : filteredArticles.slice(0, 5);

  // Mock user articles - some approved, some pending
  const userArticles: Article[] = mockArticles
    .filter((a) => a.author_id === currentUser.id)
    .map((a, index) => ({
      ...a,
      status: index === 0 ? 'pending' as const : 'approved' as const,
    }));

  return (
    <div className="min-h-screen bg-background pb-24 pt-16">
      <Header />

      <main className="py-6">
        {/* Page Title */}
        <section className="mb-6 flex items-center justify-between px-4">
          <h1 className="font-heading text-2xl font-bold">Хаб</h1>
          <Button
            onClick={() => setIsCreateModalOpen(true)}
            className="gap-2"
          >
            <Plus className="h-4 w-4" />
            Написать
          </Button>
        </section>

        {/* Categories */}
        <CategoryList
          categories={mockCategories}
          selectedId={selectedCategory?.id}
          onSelect={setSelectedCategory}
          className="mb-6"
        />

        {/* Articles Section */}
        <section className="mb-6 px-4">
          <div className="rounded-2xl bg-card p-4">
            <h2 className="mb-4 font-heading text-lg font-semibold">Статьи</h2>
            <div className="space-y-3">
              {displayedArticles.length > 0 ? (
                displayedArticles.map((article, index) => (
                  <ArticleListCard
                    key={article.id}
                    article={article}
                    className="animate-slide-up"
                    style={{ animationDelay: `${index * 50}ms` }}
                  />
                ))
              ) : (
                <p className="py-8 text-center text-muted-foreground">
                  Нет статей в этой категории
                </p>
              )}
            </div>

            {/* Show all button */}
            {filteredArticles.length > 5 && !showAllArticles && (
              <Button
                variant="outline"
                className="mt-4 w-full gap-2"
                onClick={() => setShowAllArticles(true)}
              >
                Смотреть все
                <ChevronRight className="h-4 w-4" />
              </Button>
            )}
          </div>
        </section>

        {/* My Articles Section */}
        <section className="px-4">
          <div className="rounded-2xl bg-card p-4">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="font-heading text-lg font-semibold">Мои статьи</h2>
              {userArticles.length > 0 && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="gap-1"
                  onClick={() => setIsMyArticlesOpen(true)}
                >
                  Все
                  <ChevronRight className="h-4 w-4" />
                </Button>
              )}
            </div>

            {userArticles.length === 0 ? (
              <div className="py-8 text-center">
                <FileText className="mx-auto mb-2 h-8 w-8 text-muted-foreground" />
                <p className="text-muted-foreground">Вы ничего не написали</p>
                <Button
                  variant="outline"
                  className="mt-4 gap-2"
                  onClick={() => setIsCreateModalOpen(true)}
                >
                  <Plus className="h-4 w-4" />
                  Написать статью
                </Button>
              </div>
            ) : (
              <div className="space-y-3">
                {userArticles.slice(0, 3).map((article, index) => (
                  <ArticleListCard
                    key={article.id}
                    article={article}
                    showStatus
                    className="animate-slide-up"
                    style={{ animationDelay: `${index * 50}ms` }}
                  />
                ))}
              </div>
            )}
          </div>
        </section>
      </main>

      <BottomNav />

      <CreateArticleModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
      />

      <UserArticlesModal
        isOpen={isMyArticlesOpen}
        onClose={() => setIsMyArticlesOpen(false)}
        articles={userArticles}
      />
    </div>
  );
}
