import { redirect } from 'next/navigation';

export default async function JobApprovalDetailRedirect({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  redirect(`/admin/job-approvals/${id}`);
}
