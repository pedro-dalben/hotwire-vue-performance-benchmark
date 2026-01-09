import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '10s', target: 20 },
    { duration: '50s', target: 20 },
  ],
};

const BASE_URL = __ENV.HOTWIRE_URL || 'http://127.0.0.1:3100';

export default function () {
  const urls = [
    `${BASE_URL}/appointments`,
    `${BASE_URL}/appointments?status=confirmed&unit_name=Unit%201`,
    `${BASE_URL}/appointments/1`,
  ];

  for (const url of urls) {
    const res = http.get(url);
    check(res, {
      'status is 200': (r) => r.status === 200,
    });
    sleep(0.5);
  }
}
