export interface WaeRow {
  [key: string]: string | number | null;
}

interface WaeQueryResponse {
  data: WaeRow[];
  meta: {
    name: string;
    type: string;
  }[];
  rows: number;
  rows_before_limit_at_least: number;
}

/**
 * Execute a SQL query against the WAE SQL API.
 */
export async function queryWAE(
  sql: string,
  accountId: string,
  apiToken: string,
): Promise<WaeRow[]> {
  const url = `https://api.cloudflare.com/client/v4/accounts/${accountId}/analytics_engine/sql`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiToken}`,
      'Content-Type': 'text/plain',
    },
    body: sql,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`WAE query failed (${response.status}): ${text}`);
  }

  const result = (await response.json()) as WaeQueryResponse;
  return result.data;
}
