import { X, Heart, MessageSquare, TrendingUp, Check, FileText } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface NotificationsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface Notification {
  id: string;
  type: 'like' | 'comment' | 'rep' | 'moderation' | 'reply';
  message: string;
  time: string;
  read: boolean;
}

const mockNotifications: Notification[] = [
  {
    id: '1',
    type: 'like',
    message: 'Вашу статью "Как выстроить систему продуктивности" оценили 12 человек',
    time: '5 мин назад',
    read: false,
  },
  {
    id: '2',
    type: 'comment',
    message: 'Новый комментарий к вашей статье от @dmitry_m',
    time: '15 мин назад',
    read: false,
  },
  {
    id: '3',
    type: 'rep',
    message: 'Ваша репутация увеличилась на +5',
    time: '1 час назад',
    read: true,
  },
  {
    id: '4',
    type: 'moderation',
    message: 'Ваша статья прошла модерацию и опубликована',
    time: '2 часа назад',
    read: true,
  },
  {
    id: '5',
    type: 'reply',
    message: '@sergey_v ответил на ваш комментарий',
    time: '3 часа назад',
    read: true,
  },
];

export function NotificationsModal({ isOpen, onClose }: NotificationsModalProps) {
  if (!isOpen) return null;

  const getIcon = (type: Notification['type']) => {
    switch (type) {
      case 'like':
        return <Heart className="h-4 w-4 text-red-500" />;
      case 'comment':
        return <MessageSquare className="h-4 w-4 text-blue-500" />;
      case 'rep':
        return <TrendingUp className="h-4 w-4 text-green-500" />;
      case 'moderation':
        return <Check className="h-4 w-4 text-green-500" />;
      case 'reply':
        return <MessageSquare className="h-4 w-4 text-purple-500" />;
    }
  };

  const unreadCount = mockNotifications.filter((n) => !n.read).length;

  return (
    <div className="fixed inset-0 z-[100]">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-background/80 backdrop-blur-sm animate-fade-in"
        onClick={onClose}
      />

      {/* Modal */}
      <div
        className={cn(
          'absolute inset-x-0 bottom-0 max-h-[80vh] overflow-y-auto rounded-t-2xl bg-card animate-slide-up',
          'md:inset-auto md:right-4 md:top-16 md:w-96 md:rounded-lg md:shadow-xl'
        )}
      >
        {/* Handle bar for mobile */}
        <div className="sticky top-0 z-10 flex justify-center bg-card pt-3 md:hidden">
          <div className="h-1 w-12 rounded-full bg-border" />
        </div>

        {/* Header */}
        <div className="flex items-center justify-between border-b border-border p-4">
          <div className="flex items-center gap-2">
            <h2 className="font-heading text-lg font-semibold">Уведомления</h2>
            {unreadCount > 0 && (
              <span className="rounded-full bg-foreground px-2 py-0.5 text-xs text-background">
                {unreadCount}
              </span>
            )}
          </div>
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X className="h-5 w-5" />
          </Button>
        </div>

        {/* Notifications list */}
        <div className="divide-y divide-border">
          {mockNotifications.map((notification) => (
            <div
              key={notification.id}
              className={cn(
                'flex items-start gap-3 p-4 transition-colors hover:bg-secondary/50',
                !notification.read && 'bg-secondary/30'
              )}
            >
              <div className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-secondary">
                {getIcon(notification.type)}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm">{notification.message}</p>
                <p className="mt-1 text-xs text-muted-foreground">{notification.time}</p>
              </div>
              {!notification.read && (
                <div className="h-2 w-2 flex-shrink-0 rounded-full bg-foreground" />
              )}
            </div>
          ))}
        </div>

        {/* Mark all as read */}
        <div className="p-4">
          <Button variant="outline" className="w-full">
            Отметить все как прочитанные
          </Button>
        </div>
      </div>
    </div>
  );
}
