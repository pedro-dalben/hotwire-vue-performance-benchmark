import { createRouter, createWebHistory } from 'vue-router'
import AppointmentsList from '../views/AppointmentsList.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/appointments'
    },
    {
      path: '/appointments',
      name: 'appointments',
      component: AppointmentsList,
    },
    {
      path: '/appointments/:id',
      name: 'appointment-detail',
      component: () => import('../views/AppointmentDetail.vue'),
    },
    {
      path: '/appointments/new',
      name: 'appointment-new',
      component: () => import('../views/AppointmentForm.vue'),
    },
    {
      path: '/appointments/:id/edit',
      name: 'appointment-edit',
      component: () => import('../views/AppointmentForm.vue'),
    },
  ],
})

export default router
