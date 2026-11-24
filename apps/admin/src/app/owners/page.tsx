import { redirect } from 'next/navigation';

export default function OwnersRedirect() {
  redirect('/admin/owners');
}
