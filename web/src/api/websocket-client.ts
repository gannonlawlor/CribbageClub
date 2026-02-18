import { Client, type IMessage } from '@stomp/stompjs'
import { WS_URL } from './config'
import { useAuthStore } from '@/auth/auth-store'

type MessageHandler = (body: unknown) => void

let client: Client | null = null
const subscriptions = new Map<string, MessageHandler>()

function getOrCreateClient(): Client {
  if (client) return client

  client = new Client({
    brokerURL: WS_URL.replace(/^http/, 'ws'),
    beforeConnect: () => {
      const token = useAuthStore.getState().token
      if (token && client) {
        client.connectHeaders = { Authorization: `Bearer ${token}` }
      }
    },
    reconnectDelay: 2000,
    heartbeatIncoming: 10000,
    heartbeatOutgoing: 10000,
    onConnect: () => {
      // Re-subscribe on reconnect
      for (const [dest, handler] of subscriptions) {
        client?.subscribe(dest, (msg: IMessage) => {
          handler(JSON.parse(msg.body))
        })
      }
    },
    onStompError: (frame) => {
      console.error('STOMP error:', frame.headers['message'])
    },
  })

  return client
}

export function connectWebSocket(): void {
  const c = getOrCreateClient()
  if (!c.active) {
    c.activate()
  }
}

export function disconnectWebSocket(): void {
  if (client?.active) {
    client.deactivate()
  }
  client = null
  subscriptions.clear()
}

export function subscribe(destination: string, handler: MessageHandler): () => void {
  subscriptions.set(destination, handler)

  if (client?.connected) {
    client.subscribe(destination, (msg: IMessage) => {
      handler(JSON.parse(msg.body))
    })
  }

  return () => {
    subscriptions.delete(destination)
  }
}

export function publish(destination: string, body: unknown): void {
  if (!client?.connected) {
    console.warn('WebSocket not connected, cannot publish to', destination)
    return
  }

  client.publish({
    destination,
    body: JSON.stringify(body),
  })
}
