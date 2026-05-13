import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
    const formData = await req.formData()

    const merchantOrderId = formData.get('merchantOrderId')?.toString()
    const resultCode = formData.get('resultCode')?.toString()
    const reference = formData.get('reference')?.toString()

    if (!merchantOrderId || !resultCode) {
        return new Response('Bad Request', { status: 400 })
    }

    const supabase = createClient(
        Deno.env.get('SB_URL')!,
        Deno.env.get('SB_SERVICE_KEY')!
    )

    if (resultCode === '00') {
        await supabase
            .from('orders')
            .update({
                payment_status: 'paid',
                work_status: 'progress',
                duitku_reference: reference,
            })
            .eq('id', merchantOrderId)
    } else {
        await supabase
            .from('orders')
            .update({ payment_status: 'failed' })
            .eq('id', merchantOrderId)
    }

    return new Response('00', { status: 200 })
})