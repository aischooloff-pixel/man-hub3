import { useState } from 'react';
import { X, Bell, User, Shield, Moon, LogOut } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { cn } from '@/lib/utils';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialTab?: 'general' | 'notifications';
}

export function SettingsModal({ isOpen, onClose, initialTab = 'general' }: SettingsModalProps) {
  const [activeTab, setActiveTab] = useState<'general' | 'notifications'>(initialTab);
  const [notifications, setNotifications] = useState({
    publication: true,
    likes: true,
    comments: true,
    rep: true,
    replies: true,
  });

  if (!isOpen) return null;

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
          'absolute inset-x-0 bottom-0 max-h-[85vh] overflow-y-auto rounded-t-2xl bg-card animate-slide-up',
          'md:inset-auto md:left-1/2 md:top-1/2 md:w-full md:max-w-md md:-translate-x-1/2 md:-translate-y-1/2 md:rounded-lg'
        )}
      >
        {/* Handle bar for mobile */}
        <div className="sticky top-0 z-10 flex justify-center bg-card pt-3 md:hidden">
          <div className="h-1 w-12 rounded-full bg-border" />
        </div>

        {/* Header */}
        <div className="flex items-center justify-between border-b border-border p-4">
          <h2 className="font-heading text-lg font-semibold">Настройки</h2>
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X className="h-5 w-5" />
          </Button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-border">
          <button
            onClick={() => setActiveTab('general')}
            className={cn(
              'flex-1 px-4 py-3 text-sm font-medium transition-colors',
              activeTab === 'general'
                ? 'border-b-2 border-foreground text-foreground'
                : 'text-muted-foreground'
            )}
          >
            Общие
          </button>
          <button
            onClick={() => setActiveTab('notifications')}
            className={cn(
              'flex-1 px-4 py-3 text-sm font-medium transition-colors',
              activeTab === 'notifications'
                ? 'border-b-2 border-foreground text-foreground'
                : 'text-muted-foreground'
            )}
          >
            Уведомления
          </button>
        </div>

        {/* Content */}
        <div className="p-4">
          {activeTab === 'general' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between rounded-lg bg-secondary/50 p-4">
                <div className="flex items-center gap-3">
                  <User className="h-5 w-5 text-muted-foreground" />
                  <span>Редактировать профиль</span>
                </div>
              </div>
              
              <div className="flex items-center justify-between rounded-lg bg-secondary/50 p-4">
                <div className="flex items-center gap-3">
                  <Shield className="h-5 w-5 text-muted-foreground" />
                  <span>Приватность</span>
                </div>
              </div>
              
              <div className="flex items-center justify-between rounded-lg bg-secondary/50 p-4">
                <div className="flex items-center gap-3">
                  <Moon className="h-5 w-5 text-muted-foreground" />
                  <span>Темная тема</span>
                </div>
                <Switch checked={true} disabled />
              </div>

              <Button variant="outline" className="w-full gap-2 text-destructive">
                <LogOut className="h-4 w-4" />
                Выйти
              </Button>
            </div>
          )}

          {activeTab === 'notifications' && (
            <div className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Уведомления будут приходить в подключенный Telegram бот
              </p>
              
              <div className="space-y-3">
                <div className="flex items-center justify-between rounded-lg bg-secondary/50 p-4">
                  <div>
                    <p className="font-medium">Публикации</p>
                    <p className="text-xs text-muted-foreground">Успешная/неуспешная публикация статьи</p>
                  </div>
                  <Switch
                    checked={notifications.publication}
                    onCheckedChange={(checked) =>
                      setNotifications((prev) => ({ ...prev, publication: checked }))
                    }
                  />
                </div>

                <div className="flex items-center justify-between rounded-lg bg-secondary/50 p-4">
                  <div>
                    <p className="font-medium">Лайки</p>
                    <p className="text-xs text-muted-foreground">Новые лайки ваших статей</p>
                  </div>
                  <Switch
                    checked={notifications.likes}
                    onCheckedChange={(checked) =>
                      setNotifications((prev) => ({ ...prev, likes: checked }))
                    }
                  />
                </div>

                <div className="flex items-center justify-between rounded-lg bg-secondary/50 p-4">
                  <div>
                    <p className="font-medium">Комментарии</p>
                    <p className="text-xs text-muted-foreground">Новые комментарии к статьям</p>
                  </div>
                  <Switch
                    checked={notifications.comments}
                    onCheckedChange={(checked) =>
                      setNotifications((prev) => ({ ...prev, comments: checked }))
                    }
                  />
                </div>

                <div className="flex items-center justify-between rounded-lg bg-secondary/50 p-4">
                  <div>
                    <p className="font-medium">Репутация</p>
                    <p className="text-xs text-muted-foreground">Изменения репутации (+/-)</p>
                  </div>
                  <Switch
                    checked={notifications.rep}
                    onCheckedChange={(checked) =>
                      setNotifications((prev) => ({ ...prev, rep: checked }))
                    }
                  />
                </div>

                <div className="flex items-center justify-between rounded-lg bg-secondary/50 p-4">
                  <div>
                    <p className="font-medium">Ответы</p>
                    <p className="text-xs text-muted-foreground">Ответы на ваши комментарии</p>
                  </div>
                  <Switch
                    checked={notifications.replies}
                    onCheckedChange={(checked) =>
                      setNotifications((prev) => ({ ...prev, replies: checked }))
                    }
                  />
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
