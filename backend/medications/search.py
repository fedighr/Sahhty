from django.contrib.postgres.search import TrigramSimilarity
from django.db.models import Q
from django.db.models.functions import Greatest
from .models import Medication


class MedicationSearch:

    @staticmethod
    def search(query: str):
        query = query.strip()

        if not query:
            return Medication.objects.none()

        if query.isnumeric():
            return Medication.objects.filter(code=query)

        exact = Medication.objects.filter(name__iexact=query)
        if exact.exists():
            return exact

        return (
            Medication.objects
            .annotate(
                name_sim=TrigramSimilarity('name', query),
                dci_sim=TrigramSimilarity('dci', query),
            )
            .annotate(
                best_score=Greatest('name_sim', 'dci_sim')
            )
            .filter(
                Q(name_sim__gte=0.4)       |
                Q(dci_sim__gte=0.4)        |
                Q(dosage__icontains=query) |
                Q(form__icontains=query)
            )
            .order_by('-best_score')
        )