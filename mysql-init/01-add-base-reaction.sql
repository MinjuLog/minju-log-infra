INSERT INTO reaction_type(
    image_url,
    reaction_key,
    render_type,
    unicode,
    workspace_id
)
SELECT
    NULL,
    'like',
    'UNICODE',
    '👍',
    1
WHERE NOT EXISTS (
    SELECT 1
    FROM reaction_type
    WHERE reaction_key = 'like'
      AND workspace_id = 1
);