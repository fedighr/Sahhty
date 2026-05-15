from django.contrib.postgres.search import TrigramSimilarity
from django.db.models import Q, Value
from django.db.models.functions import Concat, Greatest

from .models import Patient


class PatientSearch:

    @staticmethod
    def search(query: str):
        query = query.strip()

        if not query:
            return Patient.objects.none()

        exact = Patient.objects.annotate(full_name=Concat('user__first_name', Value(' '), 'user__last_name')).filter(full_name__iexact=query)

        if exact.exists():
            return exact

        return (
            Patient.objects
            .annotate(
                full_name=Concat('user__first_name', Value(' '), 'user__last_name')
            )
            .annotate(
                first_name_sim=TrigramSimilarity('user__first_name', query),
                last_name_sim=TrigramSimilarity('user__last_name', query),
                full_name_sim=TrigramSimilarity('full_name', query),
            )
            .annotate(
                best_score=Greatest('first_name_sim', 'last_name_sim', 'full_name_sim')
            )
            .filter(
                (Q(first_name_sim__gte=0.4) |
                Q(last_name_sim__gte=0.4) |
                Q(full_name_sim__gte=0.4))
            )
            .order_by('-best_score')
        )