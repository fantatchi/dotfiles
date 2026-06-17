---
name: frontend-patterns
description: Frontend development patterns for React, Next.js, state management, performance optimization, and UI best practices. Use this skill whenever working on React component design, props, or rendering; managing state with useState, useReducer, Zustand, or Context; fetching data with SWR, React Query, or server components; improving performance through memoization, virtualization, or code splitting; handling forms with Zod or controlled components; or building accessible, responsive UI, even when the user does not explicitly mention a pattern name.
---

# フロントエンド開発パターン

ReactとNext.jsで、動作が軽く保守しやすいUIを作るための実装パターンをまとめています。

## 参照する場面

Reactコンポーネントをコンポジションやpropsで組み立てるとき。useStateやuseReducer、Zustand、Contextで状態を扱うとき。SWRやReact Query、サーバーコンポーネントでデータを取得するとき。メモ化や仮想化、コード分割でパフォーマンスを上げたいとき。Zodスキーマや制御コンポーネントでフォームのバリデーションを書くとき。クライアント側のルーティングや画面遷移を扱うとき。アクセシビリティとレスポンシブに配慮したUIを組むとき。こうした場面で手を動かす前に目を通しておくと、選択肢を整理しやすくなると思います。

## コンポーネントのパターン

### 継承よりコンポジション

共通の見た目や構造は、親クラスを継承するのではなく、小さな部品を組み合わせて表現する。Cardのような入れ物を用意してヘッダーや本文を中に差し込む形にしておくと、用途ごとに自由に組み替えられます。

```typescript
// 良い例 コンポーネントのコンポジション
interface CardProps {
  children: React.ReactNode
  variant?: 'default' | 'outlined'
}

export function Card({ children, variant = 'default' }: CardProps) {
  return <div className={`card card-${variant}`}>{children}</div>
}

export function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="card-header">{children}</div>
}

export function CardBody({ children }: { children: React.ReactNode }) {
  return <div className="card-body">{children}</div>
}

// 使い方
<Card>
  <CardHeader>Title</CardHeader>
  <CardBody>Content</CardBody>
</Card>
```

### 複合コンポーネント

複数の部品が同じ状態を共有しながら連携する場合は、Contextで状態を持ち、関連するコンポーネントをひとまとまりとして公開する。タブのようにリストと中身が連動するUIに向いています。

```typescript
interface TabsContextValue {
  activeTab: string
  setActiveTab: (tab: string) => void
}

const TabsContext = createContext<TabsContextValue | undefined>(undefined)

export function Tabs({ children, defaultTab }: {
  children: React.ReactNode
  defaultTab: string
}) {
  const [activeTab, setActiveTab] = useState(defaultTab)

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      {children}
    </TabsContext.Provider>
  )
}

export function TabList({ children }: { children: React.ReactNode }) {
  return <div className="tab-list">{children}</div>
}

export function Tab({ id, children }: { id: string, children: React.ReactNode }) {
  const context = useContext(TabsContext)
  if (!context) throw new Error('Tab must be used within Tabs')

  return (
    <button
      className={context.activeTab === id ? 'active' : ''}
      onClick={() => context.setActiveTab(id)}
    >
      {children}
    </button>
  )
}

// 使い方
<Tabs defaultTab="overview">
  <TabList>
    <Tab id="overview">Overview</Tab>
    <Tab id="details">Details</Tab>
  </TabList>
</Tabs>
```

### Render Propsパターン

描画する中身を呼び出し側に決めてもらいたいときは、関数をchildrenとして受け取り、内部の状態を引数として渡す。データ取得の状態に応じて表示を切り替えるような場面で役立ちます。

```typescript
interface DataLoaderProps<T> {
  url: string
  children: (data: T | null, loading: boolean, error: Error | null) => React.ReactNode
}

export function DataLoader<T>({ url, children }: DataLoaderProps<T>) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false))
  }, [url])

  return <>{children(data, loading, error)}</>
}

// 使い方
<DataLoader<Market[]> url="/api/markets">
  {(markets, loading, error) => {
    if (loading) return <Spinner />
    if (error) return <Error error={error} />
    return <MarketList markets={markets!} />
  }}
</DataLoader>
```

## カスタムフックのパターン

### 状態管理フック

開閉の切り替えのような単純な状態は、専用のフックに切り出して再利用する。

```typescript
export function useToggle(initialValue = false): [boolean, () => void] {
  const [value, setValue] = useState(initialValue);

  const toggle = useCallback(() => {
    setValue((v) => !v);
  }, []);

  return [value, toggle];
}

// 使い方
const [isOpen, toggleOpen] = useToggle();
```

### 非同期データ取得フック

データ取得まわりの状態を共通化したいときに使えるフックです。ひとつ注意点があって、fetcherとoptionsは必ずrefに保持すること。これを怠ると、再レンダリングのたびにrefetchが作り直され、effectが回り続けて無限フェッチになります。

```typescript
interface UseQueryOptions<T> {
  onSuccess?: (data: T) => void;
  onError?: (error: Error) => void;
  enabled?: boolean;
}

export function useQuery<T>(
  key: string,
  fetcher: () => Promise<T>,
  options?: UseQueryOptions<T>,
) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState(false);

  // fetcherとoptionsを常に最新の状態でrefに保持しておくと、呼び出し側が
  // インライン関数やオブジェクトリテラルを渡してもrefetchの参照が安定する。
  // これがないと、レンダリングごとに新しいrefetchが生成され、下のeffectが
  // 状態更新のたびに再実行されて無限フェッチに陥る。
  const fetcherRef = useRef(fetcher);
  const optionsRef = useRef(options);
  useEffect(() => {
    fetcherRef.current = fetcher;
    optionsRef.current = options;
  });

  const refetch = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const result = await fetcherRef.current();
      setData(result);
      optionsRef.current?.onSuccess?.(result);
    } catch (err) {
      const error = err as Error;
      setError(error);
      optionsRef.current?.onError?.(error);
    } finally {
      setLoading(false);
    }
  }, []);

  const enabled = options?.enabled !== false;

  useEffect(() => {
    if (enabled) {
      refetch();
    }
  }, [key, enabled, refetch]);

  return { data, error, loading, refetch };
}

// 使い方
const {
  data: markets,
  loading,
  error,
  refetch,
} = useQuery("markets", () => fetch("/api/markets").then((r) => r.json()), {
  onSuccess: (data) => console.log("Fetched", data.length, "markets"),
  onError: (err) => console.error("Failed:", err),
});
```

### デバウンスフック

入力のたびに処理を走らせたくないときは、値の変化を一定時間遅らせてから反映する。検索ボックスと相性がいいです。

```typescript
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
}

// 使い方
const [searchQuery, setSearchQuery] = useState("");
const debouncedQuery = useDebounce(searchQuery, 500);

useEffect(() => {
  if (debouncedQuery) {
    performSearch(debouncedQuery);
  }
}, [debouncedQuery]);
```

## 状態管理のパターン

### ContextとReducerの組み合わせ

状態の種類が増えて更新の仕方も複数あるときは、reducerで更新ロジックをまとめ、Contextで配布する。こうしておくと状態の流れの見通しがよくなります。

```typescript
interface State {
  markets: Market[]
  selectedMarket: Market | null
  loading: boolean
}

type Action =
  | { type: 'SET_MARKETS'; payload: Market[] }
  | { type: 'SELECT_MARKET'; payload: Market }
  | { type: 'SET_LOADING'; payload: boolean }

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'SET_MARKETS':
      return { ...state, markets: action.payload }
    case 'SELECT_MARKET':
      return { ...state, selectedMarket: action.payload }
    case 'SET_LOADING':
      return { ...state, loading: action.payload }
    default:
      return state
  }
}

const MarketContext = createContext<{
  state: State
  dispatch: Dispatch<Action>
} | undefined>(undefined)

export function MarketProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(reducer, {
    markets: [],
    selectedMarket: null,
    loading: false
  })

  return (
    <MarketContext.Provider value={{ state, dispatch }}>
      {children}
    </MarketContext.Provider>
  )
}

export function useMarkets() {
  const context = useContext(MarketContext)
  if (!context) throw new Error('useMarkets must be used within MarketProvider')
  return context
}
```

## パフォーマンス最適化

### メモ化

重い計算、子に渡す関数、純粋なコンポーネントは、必要なときだけ再計算と再描画が走るようにする。useMemoとuseCallback、React.memoを使い分ける。配列をソートするときは、元の配列を壊さないよう必ずコピーしてから並べ替えること。

```typescript
// 良い例 重い計算にはuseMemoを使う
// ソート前にコピーする。Array.prototype.sortは元の配列を変更するため
const sortedMarkets = useMemo(() => {
  return [...markets].sort((a, b) => b.volume - a.volume)
}, [markets])

// 良い例 子に渡す関数にはuseCallbackを使う
const handleSearch = useCallback((query: string) => {
  setSearchQuery(query)
}, [])

// 良い例 純粋なコンポーネントにはReact.memoを使う
export const MarketCard = React.memo<MarketCardProps>(({ market }) => {
  return (
    <div className="market-card">
      <h3>{market.name}</h3>
      <p>{market.description}</p>
    </div>
  )
})
```

### コード分割と遅延ロード

最初の表示に不要な重いコンポーネントは、遅延ロードして必要になってから読み込む。Suspenseでフォールバックを用意しておくと、読み込み中の表示も制御できます。

```typescript
import { lazy, Suspense } from 'react'

// 良い例 重いコンポーネントは遅延ロードする
const HeavyChart = lazy(() => import('./HeavyChart'))
const ThreeJsBackground = lazy(() => import('./ThreeJsBackground'))

export function Dashboard() {
  return (
    <div>
      <Suspense fallback={<ChartSkeleton />}>
        <HeavyChart data={data} />
      </Suspense>

      <Suspense fallback={null}>
        <ThreeJsBackground />
      </Suspense>
    </div>
  )
}
```

### 長いリストの仮想化

何百件もある一覧をそのまま描画すると重くなる。画面に映っている分だけ描画する仮想化を使う。@tanstack/react-virtualのuseVirtualizerが使えます。

```typescript
import { useVirtualizer } from '@tanstack/react-virtual'

export function VirtualMarketList({ markets }: { markets: Market[] }) {
  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: markets.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100,  // 行の高さの見積もり
    overscan: 5  // 余分に描画する項目数
  })

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative'
        }}
      >
        {virtualizer.getVirtualItems().map(virtualRow => (
          <div
            key={virtualRow.index}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualRow.size}px`,
              transform: `translateY(${virtualRow.start}px)`
            }}
          >
            <MarketCard market={markets[virtualRow.index]} />
          </div>
        ))}
      </div>
    </div>
  )
}
```

## フォーム処理のパターン

### バリデーション付きの制御フォーム

入力値をstateで管理し、送信前に検証してエラーを表示する。値とエラーをそれぞれ持っておき、検証関数で必須チェックや文字数チェックをまとめると扱いやすくなります。

```typescript
interface FormData {
  name: string
  description: string
  endDate: string
}

interface FormErrors {
  name?: string
  description?: string
  endDate?: string
}

export function CreateMarketForm() {
  const [formData, setFormData] = useState<FormData>({
    name: '',
    description: '',
    endDate: ''
  })

  const [errors, setErrors] = useState<FormErrors>({})

  const validate = (): boolean => {
    const newErrors: FormErrors = {}

    if (!formData.name.trim()) {
      newErrors.name = 'Name is required'
    } else if (formData.name.length > 200) {
      newErrors.name = 'Name must be under 200 characters'
    }

    if (!formData.description.trim()) {
      newErrors.description = 'Description is required'
    }

    if (!formData.endDate) {
      newErrors.endDate = 'End date is required'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!validate()) return

    try {
      await createMarket(formData)
      // 成功時の処理
    } catch (error) {
      // エラー時の処理
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={formData.name}
        onChange={e => setFormData(prev => ({ ...prev, name: e.target.value }))}
        placeholder="Market name"
      />
      {errors.name && <span className="error">{errors.name}</span>}

      {/* 他のフィールド */}

      <button type="submit">Create Market</button>
    </form>
  )
}
```

## エラーバウンダリのパターン

配下のコンポーネントで例外が起きたときに、アプリ全体を落とさず代替表示に切り替えるには、エラーバウンダリを使う。クラスコンポーネントで実装します。

```typescript
interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  ErrorBoundaryState
> {
  state: ErrorBoundaryState = {
    hasError: false,
    error: null
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error boundary caught:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-fallback">
          <h2>Something went wrong</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      )
    }

    return this.props.children
  }
}

// 使い方
<ErrorBoundary>
  <App />
</ErrorBoundary>
```

## アニメーションのパターン

### Framer Motionのアニメーション

リストの出入りやモーダルの開閉になめらかな動きをつけたいときは、Framer Motionを使う。AnimatePresenceで要素の追加と削除をアニメーションできます。

```typescript
import { motion, AnimatePresence } from 'framer-motion'

// 良い例 リストのアニメーション
export function AnimatedMarketList({ markets }: { markets: Market[] }) {
  return (
    <AnimatePresence>
      {markets.map(market => (
        <motion.div
          key={market.id}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.3 }}
        >
          <MarketCard market={market} />
        </motion.div>
      ))}
    </AnimatePresence>
  )
}

// 良い例 モーダルのアニメーション
export function Modal({ isOpen, onClose, children }: ModalProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="modal-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          <motion.div
            className="modal-content"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
          >
            {children}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
```

## アクセシビリティのパターン

### キーボード操作

マウスがなくても使えるように、矢印キーやEnter、Escでの操作に対応する。キー入力を拾って、選択位置の移動や確定、閉じる動作を割り当てます。

```typescript
export function Dropdown({ options, onSelect }: DropdownProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [activeIndex, setActiveIndex] = useState(0)

  const handleKeyDown = (e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault()
        setActiveIndex(i => Math.min(i + 1, options.length - 1))
        break
      case 'ArrowUp':
        e.preventDefault()
        setActiveIndex(i => Math.max(i - 1, 0))
        break
      case 'Enter':
        e.preventDefault()
        onSelect(options[activeIndex])
        setIsOpen(false)
        break
      case 'Escape':
        setIsOpen(false)
        break
    }
  }

  return (
    <div
      role="combobox"
      aria-expanded={isOpen}
      aria-haspopup="listbox"
      onKeyDown={handleKeyDown}
    >
      {/* ドロップダウンの実装 */}
    </div>
  )
}
```

### フォーカス管理

モーダルを開いたらその中にフォーカスを移し、閉じたら元の要素に戻す。開く前のフォーカス位置を覚えておくのがポイントです。

```typescript
export function Modal({ isOpen, onClose, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null)
  const previousFocusRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (isOpen) {
      // 現在フォーカスされている要素を保存
      previousFocusRef.current = document.activeElement as HTMLElement

      // モーダルにフォーカスを移す
      modalRef.current?.focus()
    } else {
      // 閉じるときにフォーカスを元へ戻す
      previousFocusRef.current?.focus()
    }
  }, [isOpen])

  return isOpen ? (
    <div
      ref={modalRef}
      role="dialog"
      aria-modal="true"
      tabIndex={-1}
      onKeyDown={e => e.key === 'Escape' && onClose()}
    >
      {children}
    </div>
  ) : null
}
```

## パターンの選び方

ここで挙げたパターンは、どれも保守性と動作の軽さを両立させるためのものです。すべてを使う必要はなく、プロジェクトの規模と複雑さに合うものだけを選んで取り入れるのがいいと思います。
