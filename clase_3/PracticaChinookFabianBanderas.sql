-- Selecciona todos los registros de la tabla Albums.
SELECT * FROM album;

-- Selecciona todos los géneros únicos de la tabla Genres.
SELECT DISTINCT name FROM genre;

-- Cuenta el número de pistas por género.
SELECT genre.name, COUNT(track.track_id) AS track_count
FROM genre
INNER JOIN track ON genre.genre_id = track.genre_id
GROUP BY genre.name;

-- Encuentra la longitud total (en milisegundos) de todas las pistas para cada álbum.
SELECT album.title, SUM(track.milliseconds) AS total_duration
FROM album
INNER JOIN track ON album.album_id = track.album_id
GROUP BY album.title;

-- Lista los 10 álbumes con más pistas.
SELECT album.title, COUNT(track.track_id) AS track_count
FROM album
INNER JOIN track ON album.album_id = track.album_id
GROUP BY album.title
ORDER BY track_count DESC
LIMIT 10;

-- Encuentra la longitud promedio de la pista para cada género.
SELECT genre.name, AVG(track.milliseconds) AS average_duration
FROM genre
INNER JOIN track ON genre.genre_id = track.genre_id
GROUP BY genre.name;

-- Para cada cliente, encuentra la cantidad total que han gastado.
SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS total_spent
FROM customer
INNER JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name;

-- Para cada país, encuentra la cantidad total gastada por los clientes.
SELECT customer.country, SUM(invoice.total) AS total_spent
FROM customer
INNER JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.country;

-- Clasifica a los clientes en cada país por la cantidad total que han gastado.
SELECT customer.country, customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS total_spent
FROM customer
INNER JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.country, customer.customer_id, customer.first_name, customer.last_name
ORDER BY customer.country, total_spent DESC;

-- Para cada artista, encuentra el álbum con más pistas y clasifica a los artistas por este número.
SELECT artist.name AS artist_name, album.title AS album_title, COUNT(track.track_id) AS track_count
FROM artist
INNER JOIN album ON artist.artist_id = album.artist_id
INNER JOIN track ON album.album_id = track.album_id
GROUP BY artist.artist_id, artist.name, album.title
HAVING COUNT(track.track_id) = (
    SELECT MAX(track_count)
    FROM (
        SELECT artist.artist_id, COUNT(track.track_id) AS track_count
        FROM artist
        INNER JOIN album ON artist.artist_id = album.artist_id
        INNER JOIN track ON album.album_id = track.album_id
        GROUP BY artist.artist_id, album.album_id
    ) AS counts
);

-- Selecciona todas las pistas que tienen la palabra "love" en su título.
SELECT * FROM track WHERE name ILIKE '%love%';

-- Selecciona a todos los clientes cuyo primer nombre comienza con 'A'.
SELECT *
FROM customer
WHERE first_name LIKE 'A%';

-- Calcula el porcentaje del total de la factura que representa cada factura.
SELECT invoice_id, total, (total / (SELECT SUM(total) FROM invoice)) * 100 AS percentage
FROM invoice;

-- Calcula el porcentaje de pistas que representa cada género.
SELECT genre.name, COUNT(track.track_id) AS track_count, (COUNT(track.track_id) / (SELECT COUNT(*) FROM track)) * 100 AS percentage
FROM genre
INNER JOIN track ON genre.genre_id = track.genre_id
GROUP BY genre.name;

-- Para cada cliente, compara su gasto total con el del cliente que gastó más.
SELECT c1.customer_id, c1.first_name, c1.last_name, c1.total_spent,
       c2.customer_id AS highest_spender_id, c2.first_name AS highest_spender_first_name, c2.last_name AS highest_spender_last_name, c2.total_spent AS highest_spender_total
FROM (
    SELECT customer_id, first_name, last_name, SUM(total) AS total_spent
    FROM invoice
    INNER JOIN customer ON invoice.customer_id = customer.customer_id
    GROUP BY customer_id, first_name, last_name
) AS c1
CROSS JOIN (
    SELECT customer_id, first_name, last_name, SUM(total) AS total_spent
    FROM invoice
    INNER JOIN customer ON invoice.customer_id = customer.customer_id
    GROUP BY customer_id, first_name, last_name
    ORDER BY total_spent DESC
    LIMIT 1
) AS c2;

-- Para cada factura, calcula la diferencia en el gasto total entre ella y la factura anterior.
SELECT invoice_id, total, LAG(total) OVER (ORDER BY invoice_id) AS previous_total,
       total - LAG(total) OVER (ORDER BY invoice_id) AS difference
FROM invoice;

-- Para cada factura, calcula la diferencia en el gasto total entre ella y la próxima factura.
SELECT invoice_id, total, LEAD(total) OVER (ORDER BY invoice_id) AS next_total,
       LEAD(total) OVER (ORDER BY invoice_id) - total AS difference
FROM invoice;

-- Encuentra al artista con el mayor número de pistas para cada género.
WITH ranked_artists AS (
    SELECT artist.name AS artist_name, genre.name AS genre_name, COUNT(track.track_id) AS track_count,
           ROW_NUMBER() OVER (PARTITION BY genre.genre_id ORDER BY COUNT(track.track_id) DESC) AS rank
    FROM artist
    INNER JOIN album ON artist.artist_id = album.artist_id
    INNER JOIN track ON album.album_id = track.album_id
    INNER JOIN genre ON track.genre_id = genre.genre_id
    GROUP BY artist.artist_id, artist.name, genre.genre_id, genre.name
)
SELECT artist_name, genre_name, track_count
FROM ranked_artists
WHERE rank = 1;

-- Encuentra al artista que produjo más pistas el año anterior.
WITH tracks_last_year AS (
    SELECT artist.name AS artist_name, COUNT(track.track_id) AS track_count
    FROM artist
    INNER JOIN album ON artist.artist_id = album.artist_id
    INNER JOIN track ON album.album_id = track.album_id
    WHERE EXTRACT(YEAR FROM track_date) = EXTRACT(YEAR FROM NOW()) - 1
    GROUP BY artist.artist_id, artist.name
)
SELECT artist_name, track_count
FROM tracks_last_year
WHERE track_count = (SELECT MAX(track_count) FROM tracks_last_year);

-- Compara el total de la última factura de cada cliente con el total de su factura anterior.
WITH last_invoices AS (
    SELECT customer_id, total,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY invoice_date DESC) AS rank
    FROM invoice
)
SELECT i1.customer_id, i1.total AS current_total, i2.total AS previous_total,
       i1.total - i2.total AS difference
FROM last_invoices i1
JOIN last_invoices i2 ON i1.customer_id = i2.customer_id AND i1.rank = i2.rank + 1
WHERE i1.rank = 1;

-- Encuentra cuántas pistas de más de 3 minutos tiene cada álbum.
SELECT album.title, COUNT(track.track_id) AS long_track_count
FROM album
INNER JOIN track ON album.album_id = track.album_id
WHERE track.milliseconds > 180000
GROUP BY album.title;
