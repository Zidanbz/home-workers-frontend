# [Nama Endpoint]

## Ringkasan

- **Path**: `/api/...`
- **Method**: `GET|POST|PUT|PATCH|DELETE`
- **Auth**: `Ya/Tidak`
- **Owner Feature**: `[nama fitur di frontend]`

## Tujuan

Jelaskan endpoint ini dipakai untuk apa dari sisi frontend.

## Request

### Headers

```http
Authorization: Bearer <token>
Content-Type: application/json
```

### Body

```json
{
  "key": "value"
}
```

## Response Sukses

```json
{
  "success": true,
  "message": "Success",
  "data": {}
}
```

## Response Error yang Ditangani UI

```json
{
  "success": false,
  "message": "Validation Error"
}
```

## Catatan UI Handling

- Pesan error yang harus ditampilkan ke user:
- Fallback jika response tidak valid:
