<template>
  <div class="container mx-auto px-4 py-8 max-w-2xl" data-bench-route="appointment-detail">
    <div class="mb-4">
      <router-link to="/appointments" class="text-blue-600 hover:underline">← Voltar</router-link>
    </div>

    <div v-if="loading" class="text-center py-8">Carregando...</div>
    <div v-else-if="error" class="text-red-600 py-8">{{ error }}</div>
    <div v-else-if="appointment" class="bg-white p-6 rounded-lg shadow">
      <h1 class="text-2xl font-bold mb-4">Appointment #{{ appointment.id }}</h1>

      <div class="space-y-3">
        <div>
          <strong class="text-gray-700">Beneficiário:</strong>
          <p class="text-gray-900">{{ appointment.beneficiary_name }}</p>
        </div>

        <div>
          <strong class="text-gray-700">Profissional:</strong>
          <p class="text-gray-900">{{ appointment.professional_name }}</p>
        </div>

        <div>
          <strong class="text-gray-700">Unidade:</strong>
          <p class="text-gray-900">{{ appointment.unit_name }}</p>
        </div>

        <div>
          <strong class="text-gray-700">Data/Hora:</strong>
          <p class="text-gray-900">{{ formatDate(appointment.starts_at) }}</p>
        </div>

        <div>
          <strong class="text-gray-700">Status:</strong>
          <span
            :class="[
              'px-2 py-1 text-xs rounded',
              appointment.status === 'confirmed' ? 'bg-green-100 text-green-800' :
              appointment.status === 'canceled' ? 'bg-red-100 text-red-800' :
              appointment.status === 'done' ? 'bg-blue-100 text-blue-800' :
              'bg-gray-100 text-gray-800'
            ]"
          >
            {{ appointment.status }}
          </span>
        </div>

        <div v-if="appointment.notes">
          <strong class="text-gray-700">Notas:</strong>
          <p class="text-gray-900">{{ appointment.notes }}</p>
        </div>
      </div>

      <div class="mt-6">
        <router-link
          :to="`/appointments/${appointment.id}/edit`"
          class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 mr-2"
        >
          Editar
        </router-link>
        <button
          @click="deleteAppointment"
          class="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
        >
          Remover
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()
const API_URL = 'http://127.0.0.1:3200/api/appointments'

const appointment = ref(null)
const loading = ref(false)
const error = ref(null)

const fetchAppointment = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await fetch(`${API_URL}/${route.params.id}`)
    if (!response.ok) throw new Error('Erro ao carregar appointment')
    appointment.value = await response.json()
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

const deleteAppointment = async () => {
  if (!confirm('Tem certeza?')) return

  try {
    const response = await fetch(`${API_URL}/${route.params.id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error('Erro ao remover appointment')
    router.push('/appointments')
  } catch (err) {
    alert(err.message)
  }
}

const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

onMounted(() => {
  fetchAppointment()
})
</script>

