<template>
  <div class="container mx-auto px-4 py-8 max-w-2xl" :data-bench-route="isEdit ? 'appointment-edit' : 'appointment-new'">
    <div class="mb-4">
      <router-link to="/appointments" class="text-blue-600 hover:underline">← Voltar</router-link>
    </div>

    <div class="bg-white p-6 rounded-lg shadow">
      <h1 class="text-2xl font-bold mb-4">{{ isEdit ? 'Editar' : 'Novo' }} Appointment</h1>

      <form @submit.prevent="submitForm">
        <div v-if="errors.length > 0" class="mb-4 p-4 bg-red-50 border border-red-200 rounded">
          <h2 class="text-red-800 font-bold mb-2">Erros:</h2>
          <ul class="list-disc list-inside text-red-700">
            <li v-for="error in errors" :key="error">{{ error }}</li>
          </ul>
        </div>

        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-1">Beneficiário *</label>
            <input
              v-model="form.beneficiary_name"
              type="text"
              required
              minlength="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">Profissional *</label>
            <input
              v-model="form.professional_name"
              type="text"
              required
              minlength="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">Unidade *</label>
            <input
              v-model="form.unit_name"
              type="text"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">Data/Hora *</label>
            <input
              v-model="form.starts_at"
              type="datetime-local"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">Status</label>
            <select
              v-model="form.status"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="scheduled">Scheduled</option>
              <option value="confirmed">Confirmed</option>
              <option value="canceled">Canceled</option>
              <option value="done">Done</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-1">Notas</label>
            <textarea
              v-model="form.notes"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
            ></textarea>
          </div>
        </div>

        <div class="mt-6">
          <button
            type="submit"
            :disabled="submitting"
            class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
          >
            {{ submitting ? 'Salvando...' : (isEdit ? 'Atualizar' : 'Criar') }}
          </button>
          <router-link
            to="/appointments"
            class="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 ml-2"
          >
            Cancelar
          </router-link>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()
const API_URL = 'http://127.0.0.1:3200/api/appointments'

const isEdit = computed(() => !!route.params.id)

const form = ref({
  beneficiary_name: '',
  professional_name: '',
  unit_name: '',
  starts_at: '',
  status: 'scheduled',
  notes: ''
})

const errors = ref([])
const submitting = ref(false)

const fetchAppointment = async () => {
  if (!isEdit.value) return

  try {
    const response = await fetch(`${API_URL}/${route.params.id}`)
    if (!response.ok) throw new Error('Erro ao carregar appointment')
    const data = await response.json()
    form.value = {
      beneficiary_name: data.beneficiary_name,
      professional_name: data.professional_name,
      unit_name: data.unit_name,
      starts_at: new Date(data.starts_at).toISOString().slice(0, 16),
      status: data.status,
      notes: data.notes || ''
    }
  } catch (err) {
    errors.value = [err.message]
  }
}

const submitForm = async () => {
  errors.value = []
  submitting.value = true

  try {
    const url = isEdit.value ? `${API_URL}/${route.params.id}` : API_URL
    const method = isEdit.value ? 'PATCH' : 'POST'

    const payload = {
      ...form.value,
      starts_at: new Date(form.value.starts_at).toISOString()
    }

    const response = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ appointment: payload })
    })

    const data = await response.json()

    if (!response.ok) {
      if (data.errors) {
        errors.value = Array.isArray(data.errors) ? data.errors : Object.values(data.errors).flat()
      } else {
        errors.value = ['Erro ao salvar appointment']
      }
      return
    }

    router.push(`/appointments/${data.id}`)
  } catch (err) {
    errors.value = [err.message]
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  fetchAppointment()
})
</script>

