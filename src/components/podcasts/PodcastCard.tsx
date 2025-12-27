import { Play, Clock } from 'lucide-react';
import { Podcast } from '@/types';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface PodcastCardProps {
  podcast: Podcast;
  onPlay: (podcast: Podcast) => void;
  className?: string;
  style?: React.CSSProperties;
}

export function PodcastCard({ podcast, onPlay, className, style }: PodcastCardProps) {
  return (
    <div
      className={cn(
        'group relative flex w-[280px] flex-shrink-0 flex-col overflow-hidden rounded-xl bg-secondary/50 transition-smooth hover:bg-secondary',
        className
      )}
      style={style}
    >
      {/* 16:9 aspect ratio for full YouTube thumbnail */}
      <div className="relative aspect-video overflow-hidden rounded-t-xl">
        <img
          src={podcast.thumbnail_url}
          alt={podcast.title}
          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
          onError={(e) => {
            e.currentTarget.src = `https://img.youtube.com/vi/${podcast.youtube_id}/hqdefault.jpg`;
          }}
        />
        <div className="absolute inset-0 flex items-center justify-center bg-background/40 opacity-0 transition-opacity group-hover:opacity-100">
          <Button
            size="icon"
            className="h-12 w-12 rounded-full shadow-elevated"
            onClick={() => onPlay(podcast)}
          >
            <Play className="h-5 w-5 fill-current" />
          </Button>
        </div>
        <div className="absolute bottom-2 right-2 flex items-center gap-1 rounded-full bg-background/80 px-2 py-1 text-xs backdrop-blur-sm">
          <Clock className="h-3 w-3" />
          <span>{podcast.duration}</span>
        </div>
      </div>

      <div className="p-3">
        <h3 className="mb-1 line-clamp-2 text-sm font-medium leading-tight">
          {podcast.title}
        </h3>
        <p className="line-clamp-2 text-xs text-muted-foreground">
          {podcast.description}
        </p>
      </div>
    </div>
  );
}
