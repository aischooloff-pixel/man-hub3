import { Heart, MessageCircle, Bookmark, Clock, Check, XCircle } from 'lucide-react';
import { Article } from '@/types';
import { cn } from '@/lib/utils';

interface ArticleListCardProps {
  article: Article;
  className?: string;
  style?: React.CSSProperties;
  showStatus?: boolean;
}

export function ArticleListCard({ article, className, style, showStatus }: ArticleListCardProps) {
  const getStatusBadge = () => {
    if (!showStatus) return null;
    switch (article.status) {
      case 'pending':
        return (
          <span className="flex items-center gap-1 rounded-full bg-yellow-500/20 px-2 py-0.5 text-[10px] text-yellow-500">
            <Clock className="h-2.5 w-2.5" />
            На модерации
          </span>
        );
      case 'rejected':
        return (
          <span className="flex items-center gap-1 rounded-full bg-red-500/20 px-2 py-0.5 text-[10px] text-red-500">
            <XCircle className="h-2.5 w-2.5" />
            Отклонено
          </span>
        );
      default:
        return null;
    }
  };

  return (
    <article
      className={cn(
        'group cursor-pointer rounded-full bg-secondary/50 px-4 py-3 transition-all hover:bg-secondary',
        className
      )}
      style={style}
    >
      <div className="flex items-center gap-3">
        <img
          src={article.is_anonymous ? '/placeholder.svg' : article.author.avatar_url || '/placeholder.svg'}
          alt={article.is_anonymous ? 'Аноним' : article.author.first_name}
          className="h-10 w-10 flex-shrink-0 rounded-full object-cover"
        />
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <h3 className="truncate font-medium text-foreground group-hover:text-primary transition-colors">
              {article.title}
            </h3>
            {getStatusBadge()}
          </div>
          <div className="flex items-center gap-3 text-xs text-muted-foreground">
            <span>{article.is_anonymous ? 'Аноним' : article.author.first_name}</span>
            <span>•</span>
            <div className="flex items-center gap-1">
              <Heart className="h-3 w-3" />
              {article.likes_count}
            </div>
            <div className="flex items-center gap-1">
              <MessageCircle className="h-3 w-3" />
              {article.comments_count}
            </div>
          </div>
        </div>
        <Bookmark className="h-4 w-4 text-muted-foreground" />
      </div>
    </article>
  );
}
