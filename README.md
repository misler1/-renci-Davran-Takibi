# Ogrenci Davranis Takibi (Web + iOS + Android)

Bu proje Replit'e bagli olmadan calisacak sekilde duzenlendi.
Frontend ve backend birbirinden ayrildi, mobil paketleme icin Capacitor eklendi.

## Teknoloji Secimi

- `Web`: React + Vite + Tailwind (mevcut tasarim aynen korunur)
- `API`: Express + PostgreSQL + Drizzle
- `Mobil`: Capacitor (ayni web arayuzu iOS ve Android uygulamasina doner)

Bu secimle ayni kod tabaniyla `web + iOS + Android` cikisi alinabilir.

## Kurulum

1. `.env.example` dosyasini kopyalayi `/.env` olustur.
2. `DATABASE_URL`, `SESSION_SECRET`, `VITE_API_BASE_URL` degerlerini doldur.
3. Paketleri yukle:

```bash
npm install
```

## Gelistirme

Web ve API'yi birlikte calistir:

```bash
npm run dev
```

- Web: `http://localhost:5173`
- API: `http://localhost:5000`

## Uretim Build

```bash
npm run build
npm run start
```

## Mobil Donusum (Capacitor)

Ilk kurulumdan sonra:

```bash
npm run mobile:sync
```

Android Studio ac:

```bash
npm run mobile:android
```

Xcode ac:

```bash
npm run mobile:ios
```

Notlar:
- iOS build sadece macOS + Xcode ortaminda alinabilir.
- Telefon/emulator API'ye erisebilmeli. Bu nedenle `VITE_API_BASE_URL` yerel IP veya domain olmalidir.
- `CORS_ORIGIN` icine kullandigin web/mobil originlerini ekle.

## Temizlenen Replit Bagimliliklari

- `.replit` dosyasi kaldirildi.
- Replit Vite pluginleri kaldirildi.
- Replit'e ozel dev-server entegrasyonu kaldirildi.
