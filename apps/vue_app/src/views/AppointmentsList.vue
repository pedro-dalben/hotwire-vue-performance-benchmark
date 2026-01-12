<template>
  <div class="container mx-auto px-4 py-8" data-bench-route="appointments">
    <h1 class="text-3xl font-bold mb-6">Appointments</h1>

    <div class="mb-4">
      <router-link to="/appointments/new" class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700">
        Novo Appointment
      </router-link>
    </div>

    <form @submit.prevent="applyFilters" class="mb-6">
      <div class="grid grid-cols-1 md:grid-cols-5 gap-4 mb-4">
        <div>
          <label class="block text-sm font-medium mb-1">Buscar beneficiário</label>
          <input
            v-model="filters.q"
            type="text"
            placeholder="Nome..."
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Status</label>
          <select
            v-model="filters.status"
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
          >
            <option value="">Todos</option>
            <option value="scheduled">Scheduled</option>
            <option value="confirmed">Confirmed</option>
            <option value="canceled">Canceled</option>
            <option value="done">Done</option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Unidade</label>
          <input
            v-model="filters.unit_name"
            type="text"
            placeholder="Unidade..."
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Data início</label>
          <input
            v-model="filters.start_date"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
          />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Data fim</label>
          <input
            v-model="filters.end_date"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
          />
        </div>
      </div>

      <div>
        <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
          Filtrar
        </button>
        <button type="button" @click="clearFilters" class="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 ml-2">
          Limpar
        </button>
      </div>
    </form>

    <div v-if="loading" class="text-center py-8">Carregando...</div>
    <div v-else-if="error" class="text-red-600 py-8">{{ error }}</div>
    <div v-else>
      <div class="overflow-x-auto">
        <table class="min-w-full bg-white border border-gray-300">
          <thead class="bg-gray-100">
            <tr>
              <th class="px-4 py-2 text-left border-b">ID</th>
              <th class="px-4 py-2 text-left border-b">Beneficiário</th>
              <th class="px-4 py-2 text-left border-b">Profissional</th>
              <th class="px-4 py-2 text-left border-b">Unidade</th>
              <th class="px-4 py-2 text-left border-b">Data/Hora</th>
              <th class="px-4 py-2 text-left border-b">Status</th>
              <th class="px-4 py-2 text-left border-b">Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="appointment in appointments" :key="appointment.id" class="hover:bg-gray-50">
              <td class="px-4 py-2 border-b">{{ appointment.id }}</td>
              <td class="px-4 py-2 border-b">{{ appointment.beneficiary_name }}</td>
              <td class="px-4 py-2 border-b">{{ appointment.professional_name }}</td>
              <td class="px-4 py-2 border-b">{{ appointment.unit_name }}</td>
              <td class="px-4 py-2 border-b">{{ formatDate(appointment.starts_at) }}</td>
              <td class="px-4 py-2 border-b">
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
              </td>
              <td class="px-4 py-2 border-b">
                <router-link :to="`/appointments/${appointment.id}`" class="text-blue-600 hover:underline mr-2">
                  Ver
                </router-link>
                <router-link :to="`/appointments/${appointment.id}/edit`" class="text-green-600 hover:underline mr-2">
                  Editar
                </router-link>
                <button @click="deleteAppointment(appointment.id)" class="text-red-600 hover:underline">
                  Remover
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="meta.pages > 1" class="mt-4 flex gap-2">
        <button
          v-for="page in meta.pages"
          :key="page"
          @click="goToPage(page)"
          :class="[
            'px-3 py-1 rounded',
            meta.page === page ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
          ]"
        >
          {{ page }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const API_URL = 'http://127.0.0.1:3200/api/appointments'

const router = useRouter()
const appointments = ref([])
const loading = ref(false)
const error = ref(null)
const meta = ref({ total: 0, page: 1, per_page: 25, pages: 1 })

const filters = ref({
  q: '',
  status: '',
  unit_name: '',
  start_date: '',
  end_date: ''
})

const fetchAppointments = async (page = 1) => {
  loading.value = true
  error.value = null

  try {
    const params = new URLSearchParams({
      page: page.toString(),
      per_page: '25',
      ...Object.fromEntries(Object.entries(filters.value).filter(([_, v]) => v))
    })

    const response = await fetch(`${API_URL}?${params}`)
    if (!response.ok) throw new Error('Erro ao carregar appointments')

    const data = await response.json()
    appointments.value = data.data
    meta.value = data.meta
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

const applyFilters = () => {
  fetchAppointments(1)
}

const clearFilters = () => {
  filters.value = {
    q: '',
    status: '',
    unit_name: '',
    start_date: '',
    end_date: ''
  }
  fetchAppointments(1)
}

const goToPage = (page) => {
  fetchAppointments(page)
}

const deleteAppointment = async (id) => {
  if (!confirm('Tem certeza?')) return

  try {
    const response = await fetch(`${API_URL}/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error('Erro ao remover appointment')
    fetchAppointments(meta.value.page)
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
  fetchAppointments()
})
</script>

