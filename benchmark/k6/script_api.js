import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
  stages: [
    { duration: '10s', target: 20 },
    { duration: '50s', target: 20 },
  ],
};

const BASE_URL = __ENV.API_URL || 'http://127.0.0.1:3200/api';

export default function () {
  const urls = [
    `${BASE_URL}/appointments`,
    `${BASE_URL}/appointments?status=confirmed&unit_name=Unit%201`,
    `${BASE_URL}/appointments/1`,
  ];

  const params = {
    headers: {
      'Accept': 'application/json',
    },
  };

  for (const url of urls) {
    const res = http.get(url, params);
    check(res, {
      'status is 200': (r) => r.status === 200,
    });
    sleep(0.5);
  }

  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + 7);

  const payload = JSON.stringify({
    appointment: {
      beneficiary_name: `Beneficiário ${randomString(5)}`,
      professional_name: `Profissional ${randomString(5)}`,
      unit_name: 'Unit 1',
      starts_at: futureDate.toISOString(),
      status: 'scheduled',
      notes: 'Teste k6'
    }
  });

  const postParams = {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  };

  const res = http.post(`${BASE_URL}/appointments`, payload, postParams);
  check(res, {
    'POST status is 201': (r) => r.status === 201,
  });

  sleep(0.5);
}
