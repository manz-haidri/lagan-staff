import { redirect } from 'next/navigation';

export default function WorkersRedirect() {
  redirect('/admin/workers');
}
