import { redirect } from 'next/navigation';

export default async function BusinessDetailRedirect({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  redirect(`/admin/businesses/${id}`);
}
